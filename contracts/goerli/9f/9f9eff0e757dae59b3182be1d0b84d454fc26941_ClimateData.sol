pragma solidity ^0.8.13;

contract ClimateData {
  // for lat, lon, pressure, temperature, humidity
  uint8 constant DECIMAL_PLACES = 17;

  struct SensorMeasurement {
    /* 
      Currently sensors upload lat lon with 17 digits, and longest decimal value can be 20 digits since 
      longitude ranges from -180 to 180. Thus, we need int128 since the maximum positive/negative value 
      is only ~9.2E18 for int64.
    */
    int128 lat;
    int128 lon;

    /* Pressure has 17 decimal points in the Telos updates for now, so we just used the same width as lat/lon */
    // pressure (hPa)
    uint128 pressure;

    /* Humidity has 17 decimal points in the Telos updates for now, so we just used the same width as lat/lon */
    // humidity percent
    uint128 humidity;

    /* Temperature has 17 decimal points in the Telos updates for now, so we just used the same width as lat/lon */
    // temperature (celsius)
    int128 temperature;

    /* To guarantee validity until 2100, we need 130 years, which is 4E9, which is smaller than 2^32 */
    // timestamp (unix time)
    uint32 timestamp;

    /* Troposphere (bottom layer of atmosphere) ranges to 1E4 m, so only */
    // elevation (meters)
    int16 elevation;
  }

  // the first sensor has an ID of 1, second one 2, and so on
  mapping (address => int32) private sensorID;
  int32 private numSensors;

  mapping (int32 => SensorMeasurement) private measurements;

  address private owner;

  event NewSensor(address _sensorAddr, int32 _id);
  event MeasurementUpdate(int32 _id);

  constructor() {
    owner = msg.sender;
  }

  // get whether this sensor has uploaded data before
  function isFirstTime(address _sensorAddr) private view returns(bool) {
    return sensorID[_sensorAddr] == 0;
  }

  // add a sensor to the list of all of them, only callable by owner
  function addSensor(address _sensorAddr) public {
    require(msg.sender == owner);
    require(isFirstTime(_sensorAddr));

    numSensors += 1;
    sensorID[_sensorAddr] = numSensors;
  }

  // set measurement from a sensor
  function setMeasurement(
      int128 _lat, 
      int128 _lon, 
      uint128 _pressure, 
      uint128 _humidity,
      int128 _temperature,
      uint32 _timestamp,
      int16 _elevation
    ) public {
    if (isFirstTime(msg.sender)) {
      // only owner can call addSensor so if it's a sensor coming online for the first time, 
      // just have it manually do the operations
      numSensors += 1;
      sensorID[msg.sender] = numSensors;
      emit NewSensor(msg.sender, numSensors);
    }

    int32 id = sensorID[msg.sender];
    measurements[id] = SensorMeasurement(
      _lat, 
      _lon, 
      _pressure, 
      _humidity,
      _temperature,
      _timestamp,
      _elevation
    );
    emit MeasurementUpdate(id);
  }

  // get measurement data as a sensor (only your own latest)
  function getMeasurement() public view returns(int128, int128, uint128, uint128, int128, uint32, int16) {
    SensorMeasurement storage m = measurements[sensorID[msg.sender]];
    return (
      m.lat, 
      m.lon, 
      m.pressure, 
      m.humidity,
      m.temperature,
      m.timestamp,
      m.elevation
    );
  }

  // get measurement data as owner (any sensor)
  function getMeasurement(address _sensorAddr) public view returns(int128, int128, uint128, uint128, int128, uint32, int16) {
    require(msg.sender == owner);

    SensorMeasurement storage m = measurements[sensorID[_sensorAddr]];
    return (
      m.lat, 
      m.lon, 
      m.pressure, 
      m.humidity,
      m.temperature,
      m.timestamp,
      m.elevation
    );
  }

  function getMeasurement(int32 _id) public view returns (int128, int128, uint128, uint128, int128, uint32, int16) {
    require(msg.sender == owner);

    SensorMeasurement storage m = measurements[_id];
    return (
      m.lat, 
      m.lon, 
      m.pressure, 
      m.humidity,
      m.temperature,
      m.timestamp,
      m.elevation
    );
  }

  // get the total number of sensors
  function getNumSensors() public view returns(int32) {
    require(msg.sender == owner);
    return numSensors;
  }
}