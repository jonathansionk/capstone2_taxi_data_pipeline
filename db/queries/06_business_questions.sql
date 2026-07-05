-- ============================================================
-- BUSINESS QUESTIONS
-- ============================================================


-- ============================================================
-- 1. berapa jumlah total trip valid pada Januari 2026 ?
-- ============================================================

SELECT
	COUNT(pickup_datetime) AS total_valid_trips
FROM 
	gold.vw_trip_enriched vte 
WHERE
	vte.pickup_datetime < vte.dropoff_datetime 
AND 
	vte.trip_distance > 0;


-- ============================================================
-- 2. Berapa total revenue, avg revenue, avg fare, avg tip ?
-- ============================================================
	
SELECT
	SUM(vte.total_amount ) AS total_revenue,
	AVG(vte.total_amount ) AS avg_revenue,
	AVG(vte.fare_amount ) AS avg_fare,
	AVG(vte.tip_amount ) AS avg_tip
FROM gold.vw_trip_enriched vte;


-- ============================================================
-- 3. Payment Type apa yang paling sering digunakan ?
-- ============================================================

SELECT 
	vte.payment_type_label,
	COUNT(payment_type_label) AS total_user_payment	
FROM gold.vw_trip_enriched vte
GROUP BY
	vte.payment_type_label
ORDER BY total_user_payment DESC;

-- ============================================================
-- 4. Zone pickup yang menghasilkan total revenue tertinggi?
-- ============================================================

SELECT 
	vte.pickup_zone,
	SUM(vte.total_amount ) AS total_revenue
FROM gold.vw_trip_enriched vte 
GROUP BY pickup_zone 
ORDER BY total_revenue DESC
LIMIT 5;

-- =================================================================
-- 5. zone pickup mana yang memiliki jumlah trip tertinggi?
-- =================================================================

SELECT 
	vzp."zone" AS zona_pickup,
	vzp.total_pickup_trips 
FROM gold.vw_zone_performance vzp 
ORDER BY total_pickup_trips DESC
LIMIT 5;

-- =============================================================================
-- 6.Hitung jumlah trip, revenue, dan average duration untuk setiap time period.
-- =============================================================================

SELECT 
	vte.time_period ,
	COUNT(vte.pickup_datetime ) AS jumlah_trip,
	SUM(vte.total_amount ) AS jumlah_revenue,
	AVG(vte.trip_duration_minutes ) AS average_duration_trip
FROM gold.vw_trip_enriched vte 
GROUP BY 
	time_period 
ORDER BY jumlah_revenue DESC;


-- ===========================================================================
-- 7.Cari tanggal dengan trip count sangat rendah/tinggi dibanding rata-rata. 
-- ==========================================================================

SELECT 
	vdts.pickup_date,
	vdts.total_trips ,
	(SELECT
		avg(total_trips)
	FROM gold.vw_daily_trip_summary vdts2 	
	) AS average_trip
FROM gold.vw_daily_trip_summary vdts  
WHERE 
	vdts.total_trips < (SELECT
		avg(total_trips)
	FROM gold.vw_daily_trip_summary vdts2 	
	) * 0.5
OR 
	vdts.total_trips > (SELECT
		avg(total_trips)
	FROM gold.vw_daily_trip_summary vdts2 	
	) * 1.5;
	

-- ===========================================================================
-- 8.Trip dengan durasi di atas rata-rata durasi untuk zone yang sama
-- ==========================================================================

WITH average_duration_zone AS(

SELECT 
	vte.pickup_location_id,
	avg(vte.trip_duration_minutes ) AS average_duration
FROM gold.vw_trip_enriched vte 
GROUP BY 
	pickup_location_id
)

SELECT 
	trip.trip_id,
	trip.pickup_zone,
	trip.trip_duration_minutes ,
	ZONE.average_duration
FROM gold.vw_trip_enriched AS trip
INNER JOIN average_duration_zone AS zone
	ON trip.pickup_location_id = zone.pickup_location_id
WHERE 
	trip.trip_duration_minutes  > ZONE.average_duration
ORDER BY trip.trip_duration_minutes DESC ;
	

-- ===========================================================================
-- 9.Ranking pickup zone berdasarkan total revenue. 
-- ==========================================================================

SELECT
	ZONE,
	vzp.total_revenue, 
	
	RANK() OVER (
		ORDER BY total_revenue DESC
	) AS revenue_rank
	
FROM gold.vw_zone_performance vzp
ORDER BY 
	revenue_rank

	
-- ===========================================================================
-- 10. Ranking pickup zone per borough.
-- ==========================================================================

	SELECT
		ZONE,
		borough,
		total_pickup_trips,
		
		rank() OVER(
		PARTITION BY borough	
		ORDER BY total_pickup_trips DESC
		) AS borough_rank 
		
		
	FROM gold.vw_zone_performance vzp 
	
		
	
-- ===========================================================================
-- 11. Perbandingan revenue hari ini dengan hari sebelumnya menggunakan.
-- ==========================================================================

WITH selisih_revenue AS (
SELECT
	pickup_date,
	LAG(total_revenue) OVER(
	ORDER BY pickup_date
	) AS revenue_kemarin
FROM gold.vw_daily_trip_summary vdts 
)	
	
	
SELECT 
	trip.pickup_date ,
	trip.total_revenue AS revenue_hari_ini,
	selisih.revenue_kemarin,
	trip.total_revenue - selisih.revenue_kemarin AS selisih_perbandingan_revenue
	

FROM gold.vw_daily_trip_summary AS trip
INNER JOIN selisih_revenue AS selisih
	ON trip.pickup_date = selisih.pickup_date

ORDER BY pickup_date ASC

-- ================================================================================================
-- 12.  Ambil top 3 pickup zone untuk setiap borough menggunakan ROW_NUMBER, RANK, atau DENSE_RANK.
-- ================================================================================================


WITH rank_zone AS (

SELECT
	ZONE,
	borough,
	total_pickup_trips,
	
	RANK()OVER (
	PARTITION BY borough
	ORDER BY total_pickup_trips DESC
	) AS  rank_zone_per_trips
FROM gold.vw_zone_performance vzp 

)


SELECT
	ZONE,
	borough,
	total_pickup_trips ,
	rank_zone_per_trips
	
	
FROM rank_zone
WHERE 
	rank_zone_per_trips <= 3


	




























