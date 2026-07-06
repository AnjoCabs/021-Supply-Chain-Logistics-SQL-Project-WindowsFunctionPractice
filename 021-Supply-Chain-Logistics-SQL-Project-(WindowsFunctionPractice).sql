/* 
"Designed and implemented advanced SQL queries using Window Functions including RANK(), DENSE_RANK(),
 ROW_NUMBER(), LAG(), LEAD(), NTILE(), and cumulative aggregations to analyze healthcare operations 
 and support strategic decision-making."
*/

USE supplychaindb;

-- 1. Rank carriers by total shipment volume.

SELECT 
	carrier,
    SUM(unitQuantity) AS totalVolume,
    RANK() OVER (ORDER BY SUM(unitQuantity) DESC) AS rankByVolume
FROM orderlist
GROUP BY carrier;

-- 2. Rank customers by total units ordered.

SELECT 
	customer,
    SUM(unitQuantity) AS totalQuantity,
    RANK() OVER (ORDER BY SUM(unitQuantity) DESC) AS totalQuantity
FROM orderlist 
GROUP BY customer;

-- 3. Rank products by total shipment quantity.

SELECT 
	productId,
    COUNT(orderId) AS totalOrderCount,
    DENSE_RANK() OVER (ORDER BY COUNT(orderId) DESC) AS rankOrderCount
FROM orderlist
GROUP BY productId;

-- 4. Find the top 3 products shipped from each plant.

WITH productShipments AS (
    SELECT
        plantCode,
        productId,
        SUM(unitQuantity) AS totalQuantity
    FROM orderList
    GROUP BY
        plantCode,
        productId
),
rankedProducts AS (
    SELECT
        plantCode,
        productId,
        totalQuantity,
        ROW_NUMBER() OVER (PARTITION BY plantCode ORDER BY totalQuantity DESC ) AS productRank
    FROM productShipments
)
SELECT
    plantCode,
    productId,
    totalQuantity,
    productRank
FROM rankedProducts
WHERE productRank <= 3
ORDER BY plantCode, productRank;

-- 5. Find the highest-volume customer for each carrier.

WITH rankedCustomers AS (
    SELECT
        carrier,
        customer,
        totalQuantity,
        ROW_NUMBER() OVER (PARTITION BY carrier ORDER BY totalQuantity DESC) AS customerRank
    FROM (
        SELECT 
            carrier,
            customer,
            SUM(unitQuantity) AS totalQuantity
        FROM orderlist
        GROUP BY carrier, customer
    ) t
)

SELECT 
    carrier,
    customer,
    totalQuantity
FROM rankedCustomers
WHERE customerRank = 1
ORDER BY carrier;

-- 6. Calculate cumulative shipment quantity over time.

SELECT
	YEAR(orderDate) AS year_,
    MONTH(orderDate) AS month_,
    SUM(unitQuantity) AS totalUnitQuantity,
    SUM(SUM(unitQuantity)) OVER (ORDER BY YEAR(orderDate), MONTH(orderDate)) AS cumulativeUnitQuantity
FROM orderlist
GROUP BY year_, month_
ORDER BY YEAR(orderDate), MONTH(orderDate);

-- 7. Calculate cumulative shipment weight by carrier.

SELECT 
	YEAR(orderDate) AS year_,
    MONTH(orderDate) AS month_,
	carrier,
    SUM(unitQuantity * weight) AS totalWeight,
    SUM(SUM(unitQuantity * weight)) OVER (PARTITION BY carrier ORDER BY YEAR(orderDate), MONTH(orderDate)) AS cummulativeWeight
FROM orderlist
GROUP BY year_, month_, carrier
ORDER BY carrier, year_, month_;

-- 8. Find the first shipment made by each customer.

WITH customerShipments AS (
    SELECT
        customer,
        orderId,
        orderDate,
        ROW_NUMBER() OVER (PARTITION BY customer ORDER BY orderDate) AS rn
    FROM orderList
)
SELECT
    customer,
    orderId AS firstShipmentOrderId,
    orderDate AS firstShipmentDate
FROM customerShipments
WHERE rn = 1;

-- 9.  Calculate cumulative shipment volume by plant.

SELECT
	YEAR(orderDate) AS year_,
    MONTH(orderDate) AS month_,
	plantCode,
    SUM(unitQuantity) AS totalQuantity,
    SUM(SUM(unitQuantity)) OVER (PARTITION BY plantCode ORDER BY YEAR(orderDate), MONTH(orderDate)) AS cumulativeVolume
FROM orderlist
GROUP BY plantCode, year_, month_
ORDER BY plantCode, YEAR(orderDate), MONTH(orderDate);

-- 10. Find the first shipment made by each customer.

WITH rankedShipment AS (
    SELECT
        customer,
        orderId,
        orderDate,
        ROW_NUMBER() OVER (PARTITION BY customer ORDER BY orderDate ASC, orderId ASC) AS customerRank
    FROM orderlist
)
SELECT 
    customer,
    orderId,
    orderDate
FROM rankedShipment
WHERE customerRank = 1
ORDER BY customer;

-- 11. Find the latest shipment made by each customer.

WITH customerLatestOrder AS (
    SELECT
        customer,
        orderId,
        orderDate,
        LAST_VALUE(orderId) OVER (PARTITION BY customer ORDER BY orderDate ASC, orderId ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS latestOrderId
    FROM orderlist
)
SELECT 
    customer,
    MAX(latestOrderId) AS orderId,
    MAX(orderDate) AS orderDate
FROM customerLatestOrder
GROUP BY customer
ORDER BY customer;

-- 12. Rank warehouses by daily capacity.

SELECT
	plantId,
    dailyCapacity,
    RANK() OVER(ORDER BY dailyCapacity DESC) AS rankByCapacity
FROM whcapacities
GROUP BY plantId, dailyCapacity;

-- 13. Divide customer into quartiles based on order volume.

WITH customerOrderVolume AS (
SELECT
	customer,
    SUM(unitQuantity) AS totalUnitVolume
FROM orderlist
GROUP BY customer
)
SELECT
	customer,
    totalUnitVolume,
    CASE
        WHEN NTILE(4) OVER (ORDER BY totalUnitVolume) = 1
            THEN 'Low Volume'
        WHEN NTILE(4) OVER (ORDER BY totalUnitVolume) = 2
            THEN 'Medium Volume'
        WHEN NTILE(4) OVER (ORDER BY totalUnitVolume) = 3
            THEN 'High Volume'
        ELSE 'Very High Volume' END AS totalUnitVolumeGroup
FROM customerOrderVolume
GROUP BY customer
ORDER BY totalUnitVolume DESC;

-- 14. Find the latest destination port used by each carrier.

WITH latestPort AS (
	SELECT
		orderId,
		carrier,
		orderDate,
		LAST_VALUE(orderId) OVER (PARTITION BY carrier ORDER BY orderDate ASC, orderId ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS latestPortDestination
	FROM orderlist
)
SELECT
    carrier,
    MAX(orderDate) AS latestOrderDate,
    MAX(latestPortDestination) AS latestPort
FROM latestPort
GROUP BY carrier
ORDER BY carrier;

-- 15. Divide products into 5 groups based on shipment quantity.

SELECT
	productId,
    SUM(unitQuantity) AS totalUnitQuantity,
    CASE 
		WHEN NTILE(5) OVER (ORDER BY SUM(unitQuantity)) = 1
			THEN "Low Shipment Quantity"
		WHEN NTILE(5) OVER (ORDER BY SUM(unitQuantity)) = 2
			THEN "Near Low Shipment Quantity"
		WHEN NTILE(5) OVER (ORDER BY SUM(unitQuantity)) = 3
			THEN "Medium Shipment Quanitity"
		WHEN NTILE(5) OVER (ORDER BY SUM(unitQuantity)) = 4
			THEN "High Shipment Quantity"
		ELSE "Very High Shipment Quantity" END AS shipmentQuantityLabel
FROM orderlist
GROUP BY productId;

/* 
"Designed and implemented advanced SQL queries using Window Functions including RANK(), DENSE_RANK(),
 ROW_NUMBER(), LAG(), LEAD(), NTILE(), and cumulative aggregations to analyze healthcare operations 
 and support strategic decision-making."
*/
