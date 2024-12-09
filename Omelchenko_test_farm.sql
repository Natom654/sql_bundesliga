-- 1  Вивести топ-3 клуби із найдорожчим захистом (Defender-*)
SELECT
    club, 
    ROUND(sum(price), 0) AS sum_defender_price,
    COUNT(*) AS total_defenders
FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga` 
WHERE position LIKE 'Defender%'
GROUP BY club
ORDER BY sum_defender_price DESC
LIMIT 3;

--2 У розрізі клубу та гравця порахувати, скільки гравців підписало контракт із клубом після нього

WITH PlayerContracts AS (
    SELECT 
        name,
        club,
        joined_club,
        ROW_NUMBER() OVER (PARTITION BY club ORDER BY joined_club) AS contract_order
    FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga` 
)

SELECT 
    p1.club,
    p1.name AS original_player,
    p1.joined_club AS original_contract_date,
    COUNT(p2.name) AS qty_players_after
FROM PlayerContracts p1
LEFT JOIN PlayerContracts p2 
    ON p1.club = p2.club 
    AND p2.joined_club > p1.joined_club
GROUP BY 
    p1.name, 
    p1.club, 
    p1.joined_club
ORDER BY qty_players_after DESC;


--3 Вибрати клуби, де середня вартість французьких гравців більша за 5 млн
SELECT 
    club, 
    ROUND(AVG(price), 1) AS avg_french_player_price,
    COUNT(*) AS qty_french_players
FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga` 
WHERE nationality LIKE 'France%'
GROUP BY club
HAVING avg_french_player_price > 5
ORDER BY avg_french_player_price DESC;

--4 Вибрати клуби, де частка німців вища за 90%

SELECT club
FROM (
    SELECT club, 
           COUNT(CASE WHEN nationality LIKE 'Germany%' THEN 1 END) AS german_players,
           COUNT(*) AS total_count_players
    FROM  `sturdy-hangar-444211-u2.bundesliga.bundesliga` 
    GROUP BY club
) AS club_stats
WHERE (german_players * 1.0 / total_count_players) > 0.9;


--5 Вибрати найдорожчого гравця у своєму віці (на виході ім'я + ціна)

WITH PlayerRanking AS (
    SELECT 
        name,
        price,
        age,
        RANK() OVER (PARTITION BY age ORDER BY price DESC) AS value_rank
    FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga` 
)
SELECT 
    name,
    price,
    age
FROM PlayerRanking
WHERE value_rank = 1
ORDER BY price DESC;

--6 Вибрати гравців, з вартістю у 1.5 рази більше, ніж у середньому за своєю позицією

WITH PositionAverageValue AS (
    SELECT 
        position,
        AVG(price) AS avg_position_price
    FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga` 
    GROUP BY position
)
SELECT 
    pl.name,
    pl.position,
    pl.price,
    pav.avg_position_price,
   
FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga`  pl
JOIN PositionAverageValue pav 
ON pl.position = pav.position
WHERE pl.price > 1.5 * pav.avg_position_price
order by price desc;

--7 На якій позиції найважче отримати контракт з будь-якою компанією (adidas, puma)

WITH ContractStats AS (
    SELECT 
        position,
        COUNT(*) AS total_contracts,
        SUM(CASE WHEN outfitter IN ('adidas', 'Puma') THEN 1 ELSE 0 END) AS contracts_adidas_puma,
        ROUND(100.0 * SUM(CASE WHEN outfitter IN ('adidas', 'Puma') THEN 1 ELSE 0 END) / COUNT(*), 0) AS adidas_puma_percentage
    FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga` 
    GROUP BY position
)
SELECT 
    position,
    total_contracts,
    contracts_adidas_puma,
    adidas_puma_percentage
FROM ContractStats
ORDER BY adidas_puma_percentage ASC
limit 5;

-- 8 Порахувати, в якій команді найперше закінчиться контракт у 5 гравців


SELECT club, MIN(contract_expires) AS earliest_contract_end
FROM (
    SELECT club, contract_expires
    FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga`
    where contract_expires IS NOT NULL
    ORDER BY contract_expires ASC
    LIMIT 5
) AS earliest_5
GROUP BY club
ORDER BY earliest_contract_end ASC
LIMIT 1;


--9 У якому віці гравці здебільшого виходять на пік своєї ціни

SELECT age, COUNT(*) AS peak_count_players
FROM  `sturdy-hangar-444211-u2.bundesliga.bundesliga` p1
WHERE price = (
    SELECT MAX(p2.price)
    FROM  `sturdy-hangar-444211-u2.bundesliga.bundesliga` p2
    WHERE p2.name = p1.name
)
GROUP BY age
ORDER BY peak_count_players DESC;

-- 10 У якої команди найзіграніший склад (найдовше грають разом)

WITH TeamPlayerInClub AS (
    SELECT 
        club,
        name,
        DATE_DIFF( CURRENT_DATE, joined_club, day) AS days_in_club,
       FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga`
)
SELECT 
    club,
    MAX(days_in_club) AS days_in_club
FROM TeamPlayerInClub
group by club
ORDER BY days_in_club DESC
LIMIT 10;

--11 У яких командах є тезки

SELECT club, name, COUNT(*) AS player_count
FROM `sturdy-hangar-444211-u2.bundesliga.bundesliga`
GROUP BY club, name
HAVING COUNT(*) > 1;


