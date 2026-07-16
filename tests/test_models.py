from scraper.models import Occupation, RunStats


def test_occupation_terms_are_unique_and_ordered():
    occupation = Occupation(
        1,
        "Electrician",
        [" electrician ", "Electrician Apprentice", "electrician apprentice"],
    )
    assert occupation.all_terms == ["Electrician", "Electrician Apprentice"]


def test_run_stats_dict_contains_counts():
    stats = RunStats(jobs_found=10, jobs_new=3)
    values = stats.as_dict()
    assert values["jobs_found"] == 10
    assert values["jobs_new"] == 3
