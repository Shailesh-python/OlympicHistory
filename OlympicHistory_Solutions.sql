--1.How many olympics games have been held?

SELECT 
	COUNT(DISTINCT Games) AS OlympicGameHeld 
FROM DBO.athlete_events

--2.Write a SQL query to list down all the Olympic Games held so far.

SELECT [Year], Season, City FROM DBO.athlete_events
GROUP BY [Year], Season, City 
ORDER BY [Year], Season, City 

--3. SQL query to fetch total no of countries participated in each olympic games.

SELECT Games,COUNT(1) FROM
	(
	SELECT Games,region
	FROM DBO.athlete_events AE
	LEFT JOIN DBO.noc_regions NR
		ON AE.NOC = NR.NOC
	GROUP BY Games,region
	) as cte
GROUP BY CTE.Games
ORDER BY CTE.Games

--4. Which year saw the highest and lowest no of countries participating in olympics?

;WITH CTE AS
(
SELECT Games,COUNT(1) Countries_Participated FROM
	(
	SELECT Games,region
	FROM DBO.athlete_events AE
	LEFT JOIN DBO.noc_regions NR
		ON AE.NOC = NR.NOC
	GROUP BY Games,region
	) as cte
GROUP BY CTE.Games
)
	SELECT 
		TOP 1
		CONCAT(
		FIRST_VALUE(CTE.Games) OVER (ORDER BY CTE.Countries_Participated ASC),'-',
		FIRST_VALUE(CTE.Countries_Participated) OVER (ORDER BY CTE.Countries_Participated ASC)) AS Lowest,
		CONCAT(
		FIRST_VALUE(CTE.Games) OVER (ORDER BY CTE.Countries_Participated DESC),'-',
		FIRST_VALUE(CTE.Countries_Participated) OVER (ORDER BY CTE.Countries_Participated DESC)) AS Highest
	FROM CTE


--5. Which nation has participated in all of the olympic games?

;WITH CTE AS 
(
SELECT Games,region
FROM DBO.athlete_events AE
LEFT JOIN DBO.noc_regions NR
	ON AE.NOC = NR.NOC
GROUP BY Games,region
), Participated AS
	(
	SELECT 
		CTE.region , COUNT(1) AS Times_Participated
	FROM CTE GROUP BY CTE.region
	)
		SELECT * FROM Participated 
		WHERE Times_Participated = 
			(SELECT COUNT(DISTINCT Games) FROM CTE)

--6.Identify the sport which was played in all summer olympics.

declare @@i as int
set @@i = (SELECT COUNT(DISTINCT Games) FROM DBO.athlete_events WHERE Season = 'Summer')

;WITH CTE AS
(SELECT DISTINCT Games,Sport FROM DBO.athlete_events WHERE Season = 'Summer')
,CTE_GAMEPLAYED AS 
(SELECT Sport,COUNT(1) as GamesPlayed From CTE Group by Sport)
	select * from CTE_GAMEPLAYED 
	where CTE_GAMEPLAYED.GamesPlayed = @@i

--7. Which Sports were just played only once in the olympics.

;WITH CTE AS
(SELECT DISTINCT Games,Sport FROM DBO.athlete_events)
,CTE_GAMEPLAYED AS 
(SELECT Sport,COUNT(1) as GamesPlayed From CTE Group by Sport)
	select * from CTE_GAMEPLAYED 
	where CTE_GAMEPLAYED.GamesPlayed = 1

--8. Fetch the total no of sports played in each olympic games.

;WITH CTE AS
(SELECT DISTINCT Games,Sport FROM DBO.athlete_events)
,CTE_GAMEPLAYED AS 
(SELECT Games,COUNT(1) as GamesPlayed From CTE Group by Games)
	select * from CTE_GAMEPLAYED Order by GamesPlayed desc

--9. Fetch oldest athletes to win a gold medal.

SELECT [NAME], Age FROM DBO.athlete_events 
WHERE MEDAL = 'GOLD' AND AGE = (SELECT MAX(AGE) FROM DBO.athlete_events WHERE Medal = 'GOLD')

--10. Find the Ratio of male and female athletes participated in all olympic games.

SELECT 
	SUM(IIF(SEX = 'M',1.0,0))/SUM(IIF(SEX = 'F',1.0,0)) AS M_F_RATIO
FROM 
	(
	SELECT DISTINCT ID, SEX FROM DBO.athlete_events 
	) AS SUB_QUERY


--11. Fetch the top 5 athletes who have won the most gold medals.

SELECT Name,GoldMedalWins FROM 
(
	SELECT *,
		DENSE_RANK() OVER (	ORDER BY GoldMedalWins DESC) RN
	FROM
	(
		SELECT 
		[NAME],COUNT(2) AS GoldMedalWins
		FROM 
			(
			SELECT ID,[NAME]
			FROM DBO.athlete_events
			WHERE Medal = 'GOLD'
			) R
		GROUP BY [NAME]
	)S
)T
WHERE RN <=5
ORDER BY GoldMedalWins DESC

--12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

SELECT Name,GoldMedalWins FROM 
(
	SELECT *,
		DENSE_RANK() OVER (	ORDER BY GoldMedalWins DESC) RN
	FROM
	(
		SELECT 
		[NAME],COUNT(2) AS GoldMedalWins
		FROM 
			(
			SELECT ID,[NAME]
			FROM DBO.athlete_events
			WHERE Medal in ('gold','silver','bronze')
			) R
		GROUP BY [NAME]
	)S
)T
WHERE RN <=5
ORDER BY GoldMedalWins DESC

--13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

SELECT region,GoldMedalWins FROM 
(
	SELECT *,
		DENSE_RANK() OVER (	ORDER BY GoldMedalWins DESC) RN
	FROM
	(
		SELECT 
		region,COUNT(2) AS GoldMedalWins
		FROM 
			(
			SELECT ID,[NAME],r.region
			FROM DBO.athlete_events ae
			left join dbo.noc_regions r
				on ae.noc = r.noc
			WHERE Medal in ('gold','silver','bronze')
			) R
		GROUP BY region
	)S
)T
WHERE RN <=5
ORDER BY GoldMedalWins DESC

--14. List down total gold, silver and bronze medals won by each country.

;WITH CTE_REGION_MEDALS AS
(
	SELECT 
		r.region,
		ae.medal,
		isnull(COUNT(1),0) as Medal_Won
	FROM DBO.athlete_events ae
	INNER JOIN dbo.noc_regions r
		ON ae.noc = r.noc
	WHERE Medal in ('gold','silver','bronze')
	GROUP BY r.region,ae.Medal
)
	SELECT 
		region,
		isnull([gold],0) as Gold,
		isnull([Silver],0) as Silver,
		ISNULL([Bronze],0) as Bronze
	FROM CTE_REGION_MEDALS
	PIVOT
		(
			SUM(CTE_REGION_MEDALS.MEDAL_WON)
			FOR MEDAL IN ([gold],[silver],[bronze])
		) AS PIVOT_TABLE
	ORDER BY GOLD DESC, SILVER DESC, BRONZE DESC

--16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

;WITH CTE_REGION_MEDALS AS
(
	SELECT 
		ae.Games,
		r.region,
		ae.medal,
		isnull(COUNT(1),0) as Medal_Won
	FROM DBO.athlete_events ae
	INNER JOIN dbo.noc_regions r
		ON ae.noc = r.noc
	WHERE Medal in ('gold','silver','bronze')
	GROUP BY ae.Games,r.region,ae.Medal

),T AS
	(
	SELECT 
		Games,
		region,
		isnull([gold],0) as Gold,
		isnull([Silver],0) as Silver,
		ISNULL([Bronze],0) as Bronze
	FROM CTE_REGION_MEDALS
	PIVOT
		(
			SUM(CTE_REGION_MEDALS.MEDAL_WON)
			FOR MEDAL IN ([gold],[silver],[bronze])
		) AS PIVOT_TABLE
	--ORDER BY Games,region
	)
		SELECT 
			DISTINCT
			T.Games,
			CONCAT(FIRST_VALUE(T.region) OVER (PARTITION BY T.GAMES ORDER BY T.GOLD DESC), '-', FIRST_VALUE(T.GOLD) OVER (PARTITION BY T.GAMES ORDER BY T.GOLD DESC)) AS MAX_GOLD,
			CONCAT(FIRST_VALUE(T.region) OVER (PARTITION BY T.GAMES ORDER BY T.SILVER DESC), '-', FIRST_VALUE(T.SILVER) OVER (PARTITION BY T.GAMES ORDER BY T.SILVER DESC)) AS MAX_SILVER,
			CONCAT(FIRST_VALUE(T.region) OVER (PARTITION BY T.GAMES ORDER BY T.BRONZE DESC), '-', FIRST_VALUE(T.BRONZE) OVER (PARTITION BY T.GAMES ORDER BY T.BRONZE DESC)) AS MAX_BRONZE
		FROM T


--17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

;WITH CTE_REGION_MEDALS AS
(
	SELECT 
		ae.Games,
		r.region,
		ae.medal,
		COUNT(1) as Medal_Won
	FROM DBO.athlete_events ae
	INNER JOIN dbo.noc_regions r
		ON ae.noc = r.noc
	WHERE Medal in ('gold','silver','bronze')
	GROUP BY ae.Games,r.region,ae.Medal
),T AS
(
	SELECT 
		Games,
		region,
		SUM(IIF(MEDAL = 'GOLD',Medal_Won,0)) as Gold,
		SUM(IIF(MEDAL = 'SILVER',Medal_Won,0)) as Silver,
		SUM(IIF(MEDAL = 'BRONZE',Medal_Won,0)) as Bronze,
		SUM(Medal_Won) as All_Medals
	FROM CTE_REGION_MEDALS
	GROUP BY region,Games
)		
		SELECT 
			DISTINCT
			T.Games,
			CONCAT(FIRST_VALUE(T.region) OVER (PARTITION BY T.GAMES ORDER BY T.GOLD DESC), '-', FIRST_VALUE(T.GOLD) OVER (PARTITION BY T.GAMES ORDER BY T.GOLD DESC)) AS MAX_GOLD,
			CONCAT(FIRST_VALUE(T.region) OVER (PARTITION BY T.GAMES ORDER BY T.SILVER DESC), '-', FIRST_VALUE(T.SILVER) OVER (PARTITION BY T.GAMES ORDER BY T.SILVER DESC)) AS MAX_SILVER,
			CONCAT(FIRST_VALUE(T.region) OVER (PARTITION BY T.GAMES ORDER BY T.BRONZE DESC), '-', FIRST_VALUE(T.BRONZE) OVER (PARTITION BY T.GAMES ORDER BY T.BRONZE DESC)) AS MAX_BRONZE,
			CONCAT(FIRST_VALUE(T.region) OVER (PARTITION BY T.GAMES ORDER BY All_Medals DESC), '-', FIRST_VALUE(T.All_Medals) OVER (PARTITION BY T.GAMES ORDER BY T.All_Medals DESC)) AS MAX_MEDALS
		FROM T

--18.Which countries have never won gold medal but have won silver/bronze medals?

;WITH CTE_REGION_MEDALS AS
(
	SELECT 
		r.region,
		ae.medal,
		isnull(COUNT(1),0) as Medal_Won
	FROM DBO.athlete_events ae
	INNER JOIN dbo.noc_regions r
		ON ae.noc = r.noc
	WHERE Medal in ('gold','silver','bronze')
	GROUP BY r.region,ae.Medal

),T AS
	(
	SELECT 
		region,
		isnull([gold],0) as Gold,
		isnull([Silver],0) as Silver,
		ISNULL([Bronze],0) as Bronze
	FROM CTE_REGION_MEDALS
	PIVOT
		(
			SUM(CTE_REGION_MEDALS.MEDAL_WON)
			FOR MEDAL IN ([gold],[silver],[bronze])
		) AS PIVOT_TABLE
	--ORDER BY Games,region
	)
		SELECT * FROM T 
		WHERE T.GOLD = 0

--19.Write SQL Query to return the sport which has won India the highest no of medals.

;WITH CTE_REGION_MEDALS AS
(
	SELECT 
		r.region,
		ae.Sport,
		COUNT(1) as Medal_Won
	FROM DBO.athlete_events ae
	INNER JOIN dbo.noc_regions r
		ON ae.noc = r.noc
	WHERE Medal in ('gold','silver','bronze')
	GROUP BY r.region,ae.Sport
)
	SELECT 
		Sport,
		SUM(Medal_Won) AS MEDAL_WON
	FROM CTE_REGION_MEDALS
	WHERE region = 'INDIA'
	GROUP BY Sport
	ORDER BY MEDAL_WON DESC

--20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

SELECT 
	r.region,
	ae.Sport,
	ae.games,
	COUNT(1) as Medal_Won
FROM DBO.athlete_events ae
INNER JOIN dbo.noc_regions r
	ON ae.noc = r.noc
WHERE Medal in ('gold','silver','bronze')
	AND r.region = 'INDIA'
	AND ae.Sport = 'Hockey'
GROUP BY r.region,ae.Sport,ae.games

