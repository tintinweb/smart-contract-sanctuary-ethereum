//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

//Imports
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
//Errors
error Admin__Not_Admin();
error Admin__WithdrawFailed();
error Admin__UpkeepNotTrue();
error Admin__NoBrandAvailable();

/**@title Admin Smart Contract
 *@notice This contract is only accessable by someone in authority and can be used to check & maintain brands that provide nft warranties.
 *@dev It interracts with the Brand Smart Contract to add their details in brands array & check for their warranty period.
 */
contract Admin is KeeperCompatibleInterface {
    //Type Declaration
    struct Brand {
        address brandAddress;
        string brandName;
        uint256 warrantyPeriod;
    }

    //State Variables
    address payable private immutable i_owner;
    uint256 private immutable i_interval;
    Brand[] private s_brands;
    uint256 private s_currentTimeStamp;
    mapping(uint256 => uint256) private s_warrantyPack;
    mapping(address => uint256) private s_addressToBrandIndex;

    //Events
    event BrandAdded(address indexed brandAdd);
    event WarrantyExtended(address indexed brandAdd);

    //Modifiers
    modifier onlyAdmin() {
        if (msg.sender != i_owner) revert Admin__Not_Admin();
        _;
    }

    //Constructor
    constructor(uint256 interval) {
        i_owner = payable(msg.sender);
        i_interval = interval;
        s_currentTimeStamp = block.timestamp;
        s_warrantyPack[1] = 30;
        s_warrantyPack[2] = 60;
        s_warrantyPack[3] = 90;
    }

    //Recieve or Fallback

    //Functions

    ////External

    function addBrand(
        address _brandAdd,
        string memory _brandName,
        uint256 _warrantyIndex
    ) external {
        s_addressToBrandIndex[_brandAdd] = s_brands.length;
        s_brands.push(Brand(_brandAdd, _brandName, s_warrantyPack[_warrantyIndex]));
        emit BrandAdded(_brandAdd);
    }

    function extendWarranty(address _brandAdd, uint256 _warrantyIndex) external {
        uint256 index = s_addressToBrandIndex[_brandAdd];
        s_brands[index].warrantyPeriod += s_warrantyPack[_warrantyIndex];
        emit WarrantyExtended(_brandAdd);
    }

    ////Public

    function withdraw() public onlyAdmin {
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!callSuccess) revert Admin__WithdrawFailed();
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - s_currentTimeStamp) > i_interval;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) revert Admin__UpkeepNotTrue();
        if (s_brands.length == 0) revert Admin__NoBrandAvailable();

        for (uint256 i = 0; i < s_brands.length; i++) {
            s_brands[i].warrantyPeriod -= 1;
            if (s_brands[i].warrantyPeriod == 0) {
                s_addressToBrandIndex[s_brands[i].brandAddress] = 0;
                delete (s_brands[i]);
            }
        }

        s_currentTimeStamp = block.timestamp;
    }

    //View or Pure Functions

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getNumberOfBrands() public view returns (uint256) {
        return s_brands.length;
    }

    function getWarrantyPack(uint256 index) public view returns (uint256) {
        return s_warrantyPack[index];
    }

    function getBrandAddress(uint256 index) public view returns (address) {
        return s_brands[index].brandAddress;
    }

    function getBrandName(uint256 index) public view returns (string memory) {
        return s_brands[index].brandName;
    }

    function getBrandWarrantyLeft(uint256 index) public view returns (uint256) {
        return s_brands[index].warrantyPeriod;
    }

    function getBrandIndex(address brandAdd) public view returns (uint256) {
        return s_addressToBrandIndex[brandAdd];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}