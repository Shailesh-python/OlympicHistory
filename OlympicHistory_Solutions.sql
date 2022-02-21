
--1. How many olympics games have been held?

SELECT 
	COUNT(DISTINCT Games) TotalOlympicGameHeld 
FROM DBO.athlete_events


--2. List down all Olympics games held so far.

SELECT 
	Games
FROM DBO.athlete_events
GROUP BY Games


--3. Mention the total no of nations who participated in each olympics game?

SELECT 
	SubQuery.Games,
	COUNT(*) TotalNumberOfNationsParticipated
FROM
(
	SELECT 
		DISTINCT GAMES,Team
	FROM DBO.athlete_events
) SubQuery
GROUP BY SubQuery.Games
ORDER BY TotalNumberOfNationsParticipated


--4. Which year saw the highest and lowest no of countries participating in olympics?


-- SOLUTION - 1
;WITH CountryParticipation AS
(
	SELECT 
		SubQuery.[YEAR],
		COUNT(*) TotalNumberOfNationsParticipated
	FROM
	(
		SELECT 
			DISTINCT [YEAR],Team
		FROM DBO.athlete_events
	) SubQuery
	GROUP BY SubQuery.[YEAR]
)
	SELECT * FROM (
	SELECT TOP 1 * FROM CountryParticipation
	ORDER BY TotalNumberOfNationsParticipated DESC
	) A

	UNION ALL

	SELECT * FROM (
	SELECT TOP 1 * FROM CountryParticipation
	ORDER BY TotalNumberOfNationsParticipated ASC
	) B


-- SOLUTION - 2
;WITH CountryParticipation AS
(
	SELECT 
		SubQuery.[YEAR],
		COUNT(*) TotalNumberOfNationsParticipated
	FROM
	(
		SELECT 
			DISTINCT [YEAR],Team
		FROM DBO.athlete_events
	) SubQuery
	GROUP BY SubQuery.[YEAR]
)
	SELECT YEAR,TotalNumberOfNationsParticipated
	FROM
	(
	SELECT 
		*,
		ROW_NUMBER() OVER ( ORDER BY TotalNumberOfNationsParticipated DESC) AS HighParticipation,
		ROW_NUMBER() OVER ( ORDER BY TotalNumberOfNationsParticipated ASC) AS LowParticipation
	FROM CountryParticipation
	) RESULT
	WHERE HighParticipation=1 OR LowParticipation = 1


--5. Which nation has participated in all of the olympic games?


;WITH NationParticipation AS
(
	SELECT region,Sport 
	FROM DBO.athlete_events 
	INNER JOIN DBO.noc_regions
		ON DBO.athlete_events.NOC=DBO.noc_regions.NOC
	GROUP BY region,Sport
),NationSummary AS
	(
	SELECT 
		region,
		COUNT(1) AS NationParticipated
	FROM NationParticipation
	GROUP BY region
	)
		SELECT region,NationParticipated  
		FROM  
		(
			SELECT *,
			DENSE_RANK() OVER (ORDER BY NationParticipated DESC) RN
			FROM NationSummary
		) R
		WHERE RN = 1


--6. Identify the sport which was played in all summer olympics.

DROP TABLE IF EXISTS #TEMPRESULT

SELECT * INTO #TEMPRESULT
FROM(
	SELECT 
		Year,
		Sport
	FROM DBO.athlete_events
	WHERE Season = 'Summer'
	GROUP BY YEAR,Sport
) S

SELECT Sport,COUNT(1) AS NumberOfTimesSportsPlayed
FROM #TEMPRESULT
GROUP BY Sport
HAVING COUNT(1) = (SELECT COUNT(DISTINCT(YEAR)) FROM #TEMPRESULT)


--7. Which Sports were just played only once in the olympics.

DROP TABLE IF EXISTS #TEMPRESULT

SELECT * INTO #TEMPRESULT
FROM(
	SELECT 
		Year,
		Sport
	FROM DBO.athlete_events
	WHERE Season = 'Summer'
	GROUP BY YEAR,Sport
) S

SELECT Sport,COUNT(1) AS NumberOfTimesSportsPlayed
FROM #TEMPRESULT
GROUP BY Sport
HAVING COUNT(1) = 1


--8. Fetch the total no of sports played in each olympic games.

DROP TABLE IF EXISTS #TEMPRESULT

SELECT * INTO #TEMPRESULT
FROM(
	SELECT 
		Games,
		Sport
	FROM DBO.athlete_events
	GROUP BY Games,Sport
) S

SELECT Games,COUNT(1) AS NumberOfSportsPlayed
FROM #TEMPRESULT
GROUP BY Games


--9. Fetch oldest athletes to win a gold medal

SELECT 
	*
FROM DBO.athlete_events
WHERE Medal = 'Gold' AND Age = (SELECT MAX(AGE) FROM DBO.athlete_events WHERE Medal='GOLD')


--10. Find the Ratio of male and female athletes participated in all olympic games.
--M:F


SELECT 
	SUM(CASE WHEN SEX = 'M' THEN 1.000 ELSE 0 END) / SUM(CASE WHEN SEX = 'F' THEN 1 ELSE 0 END )
FROM
(
SELECT
	DISTINCT ID,SEX
	FROM DBO.athlete_events
) R


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
			SELECT ID,NAME
			FROM DBO.athlete_events
			WHERE Medal = 'GOLD'
			) R
		GROUP BY [NAME]
	)S
)T
WHERE RN <=5
ORDER BY GoldMedalWins DESC

