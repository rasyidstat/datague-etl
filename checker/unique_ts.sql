select ts, count(*) cnt
from raw_taplog
group by 1