
USE data_scientist_project;
  
  
  -- This query creates a view purchases_info that marks whether a student's subscription was active during Q2 2021 or Q2 2022.
    
    
DROP VIEW IF EXISTS purchases_info;

-- Creating a new view named 'purchases_info'
CREATE VIEW purchases_info AS
SELECT
	*,
    -- Flag to indicate if the subscription was active during Q2 2021
    CASE 
		WHEN date_end < '2021-04-01' THEN 0 
		WHEN date_start > '2021-06-30' THEN 0 
		ELSE 1 
	END AS paid_q2_2021,
    -- Flag to indicate if the subscription was active during Q2 2022
	CASE 
		WHEN date_end < '2022-04-01' THEN 0 
		WHEN date_start > '2022-06-30' THEN 0 
		ELSE 1 
	END AS paid_q2_2022
FROM
(  -- Subquery begins
	SELECT 
		purchase_id,
		student_id,
		plan_id,
		date_start,
		IF(date_refunded IS NULL,  -- IF-ELSE construct to check if 'date_refunded' is NULL
			date_end,  -- If 'date_refunded' is NULL, then take 'date_end' as 'date_end'
			date_refunded) AS date_end  -- If 'date_refunded' is not NULL, then take 'date_refunded' as 'date_end'
	FROM
		(  -- Subquery begins
			SELECT 
				purchase_id,
				student_id,
				plan_id,
				date_purchased AS date_start,
				CASE  -- Start of CASE statement to handle different subscription plan durations
					WHEN plan_id = 0 THEN DATE_ADD(date_purchased, INTERVAL 1 MONTH)  -- If 'plan_id' is 0 (monthly subscription), then add one month to 'date_purchased' to calculate 'date_end'
					WHEN plan_id = 1 THEN DATE_ADD(date_purchased, INTERVAL 3 MONTH)  -- If 'plan_id' is 1 (quarterly subscription), then add three months to 'date_purchased' to calculate 'date_end'
					WHEN plan_id = 2 THEN DATE_ADD(date_purchased, INTERVAL 12 MONTH)  -- If 'plan_id' is 2 (annual subscription), then add twelve months to 'date_purchased' to calculate 'date_end'
					WHEN plan_id = 3 THEN CURDATE()
				END AS date_end,  
				date_refunded
		FROM
			student_purchases
		) a   
) b;   


-- This query returns the total minutes watched by students who did not pay in Q2 2022 (which is 0 for unpaid)

SELECT 
  a.student_id, 
  a.minutes_watched, 
   MAX(
	IF(i.date_start IS NULL, 0, i.paid_q2_2022)) AS paid_in_q2 
FROM 
  (
	-- Subquery to get total minutes watched by each student for a specific year
    SELECT 
      student_id, 
      ROUND(
        SUM(seconds_watched) / 60, 
        2
      ) AS minutes_watched 
    FROM 
      student_video_watched 
    WHERE 
      YEAR(date_watched) = 2022
    GROUP BY 
      student_id
  ) a 
  LEFT JOIN purchases_info i ON a.student_id = i.student_id 
GROUP BY 
  student_id, a.minutes_watched
HAVING paid_in_q2 = 0;


-- This query returns each student's total video minutes watched and number of certificates earned, even if they haven’t watched any videos.

SELECT 
    a.student_id,
      ROUND(
      COALESCE(
      SUM(w.seconds_watched), 0) / 60, 2) AS minutes_watched,
    a.certificates_issued
FROM
    (
    -- Sub-query to get the number of certificates issued per student.
    SELECT 
        student_id, 
        COUNT(certificate_id) AS certificates_issued
    FROM
        student_certificates
    GROUP BY student_id) a
        LEFT JOIN 
    student_video_watched w ON a.student_id = w.student_id
GROUP BY student_id, a.certificates_issued;




--  Calculating the number of students who watched a lecture in Q2 2021
SELECT 
    COUNT(DISTINCT student_id)
FROM
    student_video_watched
WHERE
    YEAR(date_watched) = 2021;
    
    
    
-- Calculating the number of students who watched a lecture in Q2 2022
SELECT 
    COUNT(DISTINCT student_id)
FROM
    student_video_watched
WHERE
    YEAR(date_watched) = 2022;
    
    
    
-- Calculating the number of students who watched a lecture in Q2 2021 and Q2 2022
SELECT 
    COUNT(DISTINCT student_id)
FROM
    (
    -- Subquery to get unique students who watched lectures in 2021
    SELECT DISTINCT
        student_id
    FROM
        student_video_watched
    WHERE
        YEAR(date_watched) = 2021) a 
	JOIN 
    (
    -- Subquery to get unique students who watched videos in 2022
    SELECT DISTINCT
        student_id
    FROM
        student_video_watched
    WHERE
        YEAR(date_watched) = 2022) b 
	USING(student_id);
    
    
        
-- Calculating the total number of students who watched a lecture
SELECT 
    COUNT(DISTINCT student_id)
FROM
    student_video_watched;