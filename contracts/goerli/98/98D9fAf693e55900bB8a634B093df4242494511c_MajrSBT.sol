// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MajrSBT {
  /**
   * @notice The struct that represents a single soul (identity) and all the information associated with it
   * @param identity string
   * @param url string
   * @param score uint256
   * @param timestamp uint256
   */
  struct Soul {
    string identity;
    string url;
    uint256 score;
    uint256 timestamp;
  }

  /// @notice Mapping from the user address to the soul associated with it that's minted by the contract operator
  mapping (address => Soul) private souls;

  /// @notice Mapping from the profiler address to the user address to the soul assigned to it by the profiler
  mapping (address => mapping (address => Soul)) soulProfiles;

  /// @notice Mapping from the user address to the array of the profiler addresses that have assigned a soul to it
  mapping (address => address[]) private profiles;

  /// @notice Name of the Soulbound Token
  string private _name;

  /// @notice Symbol of the Soulbound Token
  string private _symbol;

  /// @notice Operator of the Soulbound Token (a multi-sig wallet that's controlled by the MAJR DAO Guardian Council)
  address public operator;

  /// @notice A mint price that gets charged to the 3rd party profilers for minting a soul and assigning it to a user
  uint256 public price;

  /// @notice Keccak256 hash of the empty string ("")
  bytes32 private zeroHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    
  /// @notice An event that gets emitted when a soul is minted
  event Mint(address _soul);

  /// @notice An event that gets emitted when a soul is burned
  event Burn(address _soul);

  /// @notice An event that gets emitted when a soul is updated
  event Update(address _soul);

  /// @notice An event that gets emitted when a soul is profiled
  event SetProfile(address _profiler, address _soul);

  /// @notice An event that gets emitted when a soul is unprofiled
  event RemoveProfile(address _profiler, address _soul);

  /// @notice An event that gets emitted when the new operator is set
  event NewOperator(address _operator);

  /// @notice An event that gets emitted when the new price is set
  event NewPrice(uint256 _price);

  /**
   * @notice Constructor
   * @param name_ string memory
   * @param symbol_ string memory
   * @param _price uint256
   */
  constructor(string memory name_, string memory symbol_, uint256 _price) {
    require(_price > 0, "MajrSBT: Mint price must be greater than zero.");

    _name = name_;
    _symbol = symbol_;
    operator = msg.sender;
    price = _price;
  }

  /**
   * @notice Modifier which restricts the function calls to the operator of the soulbound token contract
   * @dev Only the current operator can call the methods which include this modifier
   */
  modifier onlyOperator() {
    require(msg.sender == operator, "MajrSBT: Caller is not the operator.");
    _;
  }

  /**
   * @notice Modifier which restricts the function calls to the soul address associated with the particular soul
   * @dev Only the soul address associated with the particular soul can call the methods which include this modifier
   */
  modifier onlySoul(address _soul) {
    require(_soul != address(0), "MajrSBT: Soul addres can't be address zero.");
    _;
  }

  /// @notice Modifier which requires the soul struct to be empty
  modifier soulDoesNotExist(address _soul) {
    require(keccak256(bytes(souls[_soul].identity)) == zeroHash, "MajrSBT: Soul already exists.");
    _;
  }

  /// @notice Modifier which requires the soul struct to be non-empty
  modifier soulExists(address _soul) {
    require(keccak256(bytes(souls[_soul].identity)) != zeroHash, "MajrSBT: Soul does not exist.");
    _;
  }

  /**
   * @notice Returns the name of the soulbound token
   * @return string memory
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @notice Returns the symbol of the soulbound token
   * @return string memory
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
   * @notice Mints a new soul to the associated address
   * @param _soul address
   * @param _soulData Soul calldata
   * @dev The soul must not already exist and only the operator can mint a new soul
   */
  function mint(address _soul, Soul calldata _soulData) external onlyOperator soulDoesNotExist(_soul) {
    souls[_soul] = _soulData;

    emit Mint(_soul);
  }

  /**
   * @notice Burns all the information associated to the particular address
   * @param _soul address
   * @dev Only users and the operator can burn a soul
   */
  function burn(address _soul) external {
    require(msg.sender == _soul || msg.sender == operator, "MajrSBT: Only users and issuers have rights to delete their data.");

    delete souls[_soul];

    for (uint256 i = 0; i < profiles[_soul].length; i++) {
      address profiler = profiles[_soul][i];
      delete soulProfiles[profiler][_soul];
    }

    emit Burn(_soul);
  }

  /**
   * @notice Updates the soul data associated with the particular address
   * @param _soul address
   * @param _soulData Soul calldata
   * @dev Only operator can call it and only to the souls that already exist
   */
  function update(address _soul, Soul calldata _soulData) external onlyOperator soulExists(_soul) {
    souls[_soul] = _soulData;

    emit Update(_soul);
  }

  /**
   * @notice Returns whether the soul exists or not for a particular address
   * @param _soul address
   * @return bool
   */
  function hasSoul(address _soul) external view returns (bool) {
    return keccak256(bytes(souls[_soul].identity)) == zeroHash ? false : true;
  }

  /**
   * @notice Returns the soul data associated with the particular address
   * @param _soul address
   * @return Soul memory
   */
  function getSoul(address _soul) external view returns (Soul memory) {
    return souls[_soul];
  }

  /**
   * @notice Profiles are used by 3rd parties and individual users to store data. Data is stored in a nested mapping relative to the msg.sender (it becomes a profiler in this case)
   * @param _soul address
   * @param _soulData Soul calldata
   * @dev By default, 3rd parties (profilers) can only store data on addresses that have been minted a soul and they must send the correct mint fee to do so
   */
  function setProfile(address _soul, Soul calldata _soulData) external payable soulExists(_soul) {
    require(msg.value == price, "MajrSBT: Must send the correct mint fee.");

    soulProfiles[msg.sender][_soul] = _soulData;
    profiles[_soul].push(msg.sender);

    (bool sent, ) = operator.call{value: msg.value}("");
    require(sent, "MajrSBT: Failed to send ether to the operator.");

    emit SetProfile(msg.sender, _soul);
  }

  /**
   * @notice Returns the soul data associated with the particular address relative to a profiler address that's tracking it
   * @param _profiler address
   * @param _soul address
   * @return Soul memory
   */
  function getProfile(address _profiler, address _soul) external view returns (Soul memory) {
    return soulProfiles[_profiler][_soul];
  }

  /**
   * @notice Returns all profilers that are tracking a particular address and have assigned a soul to it
   * @param _soul address
   * @return address[] memory
   */
  function listProfiles(address _soul) external view returns (address[] memory) {
    return profiles[_soul];
  }

  /**
   * @notice Returns whether the user address profiled by the profiler has the soul associated with it 
   * @param _profiler address
   * @param _soul address
   * @return bool
   */
  function hasProfile(address _profiler, address _soul) external view returns (bool) {
    return keccak256(bytes(soulProfiles[_profiler][_soul].identity)) == zeroHash ? false : true;
  }

  /**
   * @notice Let's the user remove their profiler data that's associated with the particular profiler
   * @param _profiler address
   * @param _soul address
   * @dev Only target user (soul) can call this method
   */
  function removeProfile(address _profiler, address _soul) external onlySoul(_soul) {
    delete soulProfiles[_profiler][msg.sender];

    emit RemoveProfile(_profiler, _soul);
  }

  /**
   * @notice Sets the new operator of the soulbound token contract
   * @param _operator address
   * @dev Only the current operator can call this method
   */
  function setOperator(address _operator) external onlyOperator {
    require(_operator != address(0), "MajrSBT: Operator address cannot be address zero.");

    operator = _operator;

    emit NewOperator(_operator);
  }

  /**
   * @notice Sets the new mint price that gets charged to the 3rd party profilers for minting a soul and assigning it to a user
   * @param _price uint256
   * @dev Only operator can call this method
  */
  function setPrice(uint256 _price) external onlyOperator {
    require(_price > 0, "MajrSBT: Mint price must be greater than zero.");

    price = _price;

    emit NewPrice(_price);
  }
}