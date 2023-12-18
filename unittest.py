import unittest

class TestAPIAggregation(unittest.TestCase):

    def test_pull_api_data(self):
        api_url = "https://api.open-meteo.com/v1/forecast?latitude=51.5085&longitude=-0.1257&hourly=temperature_2m,rain,showers,visibility&past_days=31"
        data = pull_api_data(api_url)
        self.assertIsNotNone(data)

    def test_aggregate_and_save(self):
        data = {
            'hourly': [
                {'timestamp': 1642464000, 'temperature_2m': 20.0, 'rain': 5.0, 'showers': 2.0, 'visibility': 10.0},
                # Add more sample data as needed
            ]
        }
        aggregate_and_save(data)
        # Add assertions for the expected result

if __name__ == "__main__":
    unittest.main()
