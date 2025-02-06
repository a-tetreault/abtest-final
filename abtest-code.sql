-- 1. We are running an experiment at an item-lvel, which means all users who visit will see the same page, but with different items, pages may differ.
-- Compare this table to the assignment events we captured for user_level_testing.
-- Does this table have everything you need to compute metrics like 30-day view-binary?

-- ANSWER: No, we will need to use the item_test_assignments to get the test assignment and test_start_date.
-- We will also need to use the view_item_events table to determine time of view events and their relativity to
-- test_start_date

SELECT *
FROM dsv1069.final_assignments

-- 2. Reformat the final_assignments_qa table to look like the final_assignments table, filling in any missing values with a placeholder of the appropriate data type
CREATE TABLE IF NOT EXISTS final_assignments (
    item_id         INT,
    test_assignment INT,
    test_number     INT,
    test_start_date DATE
);

INSERT INTO final_assignments
VALUES
    (
    SELECT
        faq.item_id,
        ita.test_assignment,
        ita.test_number,
        ita.test_Start_date
    FROM
        dsv1069.final_assignments_qa faq
    LEFT JOIN dsv1069.item_test_assignments ita
        ON ita.item_id = faq.item_id
    ORDER BY
        ita.test_number);

-- 3. Use this table to compute order_binary fro the 30-day window after test_start_date for 'item_test_2'

SELECT
    test_assignment,
    COUNT(item_id)                      AS items,
    SUM(orders_binary_30d)              AS orders_binary_30d
FROM
    (
    SELECT
        fa.item_id                      AS item_id,
        fa.test_number                  AS test_id,
        fa.test_assignment              AS test_assignment,
        MAX(CASE WHEN orders,created_at > fa.test_start_date
                 THEN 1 ELSE 0 END)     AS orders_binary,
        MAX(CASE WHEN (orders.created_at > fa.test_start_date AND
                       DATE_PART('day', orders.created_at - fa.test_start_date) <= 30
                 THEN 1 ELSE 0 END)     AS orders_binary_30d
    FROM
        dsv1069.final_assignments fa
    LEFT JOIN dsv1069.orders
        ON orders.item_id = fa.item_id
    WHERE
        fa.test_number = 'item_test_2'
    GROUP BY
        fa.item_id,
        fa.test_number,
        fa.test_assignment)             AS orders_binary
GROUP BY
    test_assignment

-- 4. Use this table to compute view_binary for the 30-day window after test_start_date for 'item_test_2'

SELECT
    test_assignment,
    COUNT(item_id)                      AS items,
    SUM(views_after_treatment_30d)      AS views_binary_30d
FROM
    (
    SELECT
        fa.item_id                      AS item_id,
        fa.test_number                  AS test_id,
        fa.test_assignment              AS test_assignment,
        MAX(CASE WHEN views.event_time > fa.test_start_date
                 THEN 1 ELSE 0 END)     AS views_after_test_binary,
        MAX(CASE WHEN (views.event_time > fa.test_start_date AND
                       DATE_PART('day', views.event_time - fa.test_start_date) <= 30
                 THEN 1 ELSE 0 END)     AS views_after_test_binary_30d
    FROM
        dsv1069.final_assignments       AS fa
    LEFT JOIN dsv1069.view_item_events  AS views
        ON views.item_id = fa.item_id
    WHERE
        fa.test_number = 'item_test_2'
    GROUP BY
        fa.item_id,
        fa.test_number,
        fa.test_assignment)             AS views_binary
GROUP BY
    test_assignment


-- 5. Use the https://thumbtack.github.io/abba/demo/abba.html to compute the lifts in metrics and the p-value for
-- the binary metrics (30-day order binary and 30- day view binary) using a 95% confidence interval.

-- 30-day order binary:
-- p-value  = 0.88
-- lift     = -1%
-- The 30-day order binary result, with a p-value of 0.88 and a lift of -1%, suggests that there is no
-- statistically significant evffect, as the p-value is much higher than the 0.5 significance threshold,
-- indicating any observed difference is likely due to random variation.

-- 30-day view binary:
-- p-value  = 0.25
-- lift     = 2.3%
-- The 30-day view binary result, with a p-value of 0.25 and a lift of 2.3%, also shows no statistically significant
-- effect, as the p-value is greater than 0.05, implying observed change in views may not be meaningful.
