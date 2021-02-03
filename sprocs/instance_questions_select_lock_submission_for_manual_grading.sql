-- BLOCK get_and_set_next_unmarked_instance_question_for_manual_grading



-- BLOCK instance_question_select_last_variant_with_submission
DROP FUNCTION IF EXISTS get_and_set_next_unmarked_instance_question_for_manual_grading(bigint, bigint, bigint);

-- Retrieves the last variant for an instance question and last submission for the variant.

CREATE OR REPLACE FUNCTION
    get_and_set_next_unmarked_instance_question_for_manual_grading(
        IN assessment_id bigint,
        IN assessment_question_id bigint,
        IN user_id bigint,
        OUT instance_question jsonb
    )
AS $$
DECLARE
    submission_id bigint;
BEGIN

    UPDATE submissions
    SET manual_grading_user = 1
    WHERE id = (
        SELECT s.id
        FROM
            instance_questions AS iq
                JOIN assessment_questions AS aq ON (aq.id = iq.assessment_question_id)
                JOIN assessments AS a ON (a.id = aq.assessment_id)
                JOIN variants AS v ON (v.instance_question_id = iq.id)
                JOIN (
                    -- We only want the LAST submissions that are created by each user to join on all
                    -- instance questions under assessment question
                    SELECT DISTINCT ON (s.auth_user_id) * FROM submissions AS s
                    WHERE s.graded_at IS NULL
                    ORDER BY s.auth_user_id, s.date DESC, s.id DESC
                ) s ON (s.variant_id = v.id)
        WHERE 
            iq.assessment_question_id = 50
            AND s.manual_grading_user IS NULL
            AND a.id = 5
        ORDER BY RANDOM()
        LIMIT 1
    )
    RETURNING id INTO submission_id;

    SELECT to_jsonb(iq.*)
    INTO instance_question
    FROM 
        instance_questions AS iq
        JOIN assessment_questions AS aq ON (aq.id = iq.assessment_question_id)
        JOIN assessments AS a ON (a.id = aq.assessment_id)
        JOIN variants AS v ON (v.instance_question_id = iq.id)
        JOIN submission AS s ON (s.variant_id = v.id)
    WHERE s.id = submission_id;

END;
$$ LANGUAGE plpgsql VOLATILE;

