/* Финальный проект третьего модуля
 * Часть 1. Расчёт метрик в SQL
 * 
*/

-- Задача 1: Расчёт MAU авторов. 
-- Здесь MAU будет определяться как количество уникальных пользователей в месяц,
-- которые читали или слушали конкретного автора. Выведите имена топ-3 авторов с 
-- наибольшим MAU в ноябре и сами значения MAU.

WITH cte1 AS (SELECT DISTINCT main_author_name, puid
              FROM bookmate.audition AS aud
              JOIN bookmate.content AS cont USING (main_content_id)
              JOIN bookmate.author AS auth USING (main_author_id)
              WHERE EXTRACT(MONTH from msk_business_dt_str::timestamp)=11)
SELECT main_author_name, COUNT(puid) AS mau
FROM cte1
GROUP BY main_author_name
ORDER BY mau DESC
LIMIT 3;

-- Задача 2: Расчёт MAU произведений.
-- Выведите имена топ-3 произведений с наибольшим MAU в ноябре, а также
-- списки жанров этих произведений, их авторов и сами значения MAU.

WITH cte1 AS (SELECT DISTINCT main_content_name,
                              published_topic_title_list,
                              main_author_name,
                              puid
              FROM bookmate.audition AS aud
              JOIN bookmate.content AS cont USING (main_content_id)
              JOIN bookmate.author AS auth USING (main_author_id)
              WHERE EXTRACT(MONTH from msk_business_dt_str::timestamp)=11)
SELECT main_content_name,
       published_topic_title_list,
       main_author_name,
       COUNT(puid) AS mau
FROM cte1
GROUP BY main_content_name,
         published_topic_title_list,
         main_author_name
ORDER BY mau DESC
LIMIT 3;

-- Задача 3: Расчёт Retention Rate
-- Нужно проанализировать ежедневный Retention Rate всех пользователей, которые были активны 2 декабря. 

WITH new_users AS (
SELECT distinct puid
FROM bookmate.audition
WHERE msk_business_dt_str::date = '2024-12-02'),

active_users AS (
SELECT distinct msk_business_dt_str::date,
                puid
FROM bookmate.audition
WHERE msk_business_dt_str::date >= '2024-12-02'),

daily_retention AS (
SELECT n.puid,
       msk_business_dt_str::date - '2024-12-02' AS day_since_install
FROM new_users n
JOIN active_users a
on n.puid = a.puid)

SELECT day_since_install,
COUNT(DISTINCT puid) AS retained_users,
ROUND(1.0 * COUNT(DISTINCT puid) / MAX(COUNT(DISTINCT puid)) OVER (ORDER by day_since_install),2) AS retention_rate
FROM daily_retention
GROUP BY 1
ORDER BY 1;

-- Задача 4: Расчёт LTV
-- Рассчитайте средние LTV для пользователей в Москве и Санкт-Петербурге
-- и сравните их между собой. Для расчёта среднего LTV используйте
-- формулу: общий доход / количество пользователей.

WITH cte1 AS (SELECT DISTINCT EXTRACT(MONTH from msk_business_dt_str::timestamp) AS month,
       usage_geo_id_name AS city,
       puid
FROM bookmate.audition AS aud
JOIN bookmate.geo AS geo USING (usage_geo_id)
WHERE usage_geo_id_name IN ('Москва', 'Санкт-Петербург'))
SELECT city,
       COUNT(DISTINCT puid) AS total_users,
       ROUND(COUNT(puid)*399*1.0/COUNT(DISTINCT puid),2) AS ltv
FROM cte1
GROUP BY city;

-- Задача 5: Расчёт средней выручки прослушанного часа — аналог среднего чека
-- Нужно рассчитать ежемесячную среднюю выручку от часа чтения или
-- прослушивания по такой формуле: выручка (MAU * 399 рублей) / сумма прослушанных часов.

SELECT DATE_TRUNC('month', msk_business_dt_str::date)::date AS month,
       COUNT(DISTINCT puid) AS mau,
       ROUND(SUM(hours),2) AS hours,
       ROUND(COUNT(DISTINCT puid)*399*1.0/SUM(hours),2) AS avg_hour_rev
FROM bookmate.audition
WHERE msk_business_dt_str::date >= '01.09.2024' AND msk_business_dt_str::date < '01.12.2024'
GROUP BY 1;
