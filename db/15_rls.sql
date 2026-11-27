CREATE ROLE schedule_group_1 NOLOGIN;
CREATE ROLE schedule_group_2 NOLOGIN;

GRANT USAGE ON SCHEMA public
TO schedule_group_1, schedule_group_2;

GRANT SELECT ON schedule_entries
TO schedule_group_1, schedule_group_2;

ALTER TABLE schedule_entries
ENABLE ROW LEVEL SECURITY;

CREATE POLICY schedule_group_access
ON schedule_entries
FOR SELECT
TO schedule_group_1, schedule_group_2
USING (
    (current_user = 'schedule_group_1' AND group_id = 1)
    OR
    (current_user = 'schedule_group_2' AND group_id = 2)
);