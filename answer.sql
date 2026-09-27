Output:
CREATE TABLE
INSERT 0 50000
ANALYZE
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1470.81..1470.83 rows=10 width=36) (actual time=3.874..3.875 rows=10.00 loops=1)
   Buffers: shared hit=417
   ->  Sort  (cost=1470.81..1474.24 rows=1374 width=36) (actual time=3.872..3.873 rows=10.00 loops=1)
         Sort Key: (sum(amount)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         Buffers: shared hit=417
         ->  HashAggregate  (cost=1423.94..1441.12 rows=1374 width=36) (actual time=3.598..3.766 rows=1314.00 loops=1)
               Group Key: customer_id
               Batches: 1  Memory Usage: 625kB
               Buffers: shared hit=417
               ->  Seq Scan on orders  (cost=0.00..1417.00 rows=1388 width=10) (actual time=0.008..3.339 rows=1326.00 loops=1)
                     Filter: ((status = 'pending'::text) AND (created_at > (now() - '30 days'::interval)))
                     Rows Removed by Filter: 48674
                     Buffers: shared hit=417
 Planning:
   Buffers: shared hit=72
 Planning Time: 0.141 ms
 Execution Time: 3.903 ms
(18 rows)

CREATE INDEX
                                                                      QUERY PLAN                                                                       
-------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=533.62..533.64 rows=10 width=36) (actual time=0.821..0.823 rows=10.00 loops=1)
   Buffers: shared hit=397 read=7
   ->  Sort  (cost=533.62..537.05 rows=1374 width=36) (actual time=0.821..0.822 rows=10.00 loops=1)
         Sort Key: (sum(amount)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         Buffers: shared hit=397 read=7
         ->  HashAggregate  (cost=486.75..503.92 rows=1374 width=36) (actual time=0.549..0.712 rows=1314.00 loops=1)
               Group Key: customer_id
               Batches: 1  Memory Usage: 625kB
               Buffers: shared hit=397 read=7
               ->  Bitmap Heap Scan on orders  (cost=35.05..479.81 rows=1388 width=10) (actual time=0.105..0.306 rows=1326.00 loops=1)
                     Recheck Cond: ((created_at > (now() - '30 days'::interval)) AND (status = 'pending'::text))
                     Heap Blocks: exact=397
                     Buffers: shared hit=397 read=7
                     ->  Bitmap Index Scan on idx_pending_recent  (cost=0.00..34.70 rows=1388 width=0) (actual time=0.075..0.076 rows=1326.00 loops=1)
                           Index Cond: (created_at > (now() - '30 days'::interval))
                           Index Searches: 1
                           Buffers: shared read=7
 Planning:
   Buffers: shared hit=30 read=1
 Planning Time: 0.114 ms
 Execution Time: 0.840 ms
(22 rows)

Ready
Light


