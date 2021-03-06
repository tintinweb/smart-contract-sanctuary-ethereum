pragma solidity ^ 0.4 .22;
contract Cession_Bien_Immobilier {

    // =================
    // State Machine
    // =================
    enum Stages {
        Initialisation,
        Lifecycle
    }
    Stages public stage = Stages.Initialisation;

    // =================
    // Public Variables
    // =================
    mapping(bytes32 => uint) public houseAddressToId;
    mapping(address => uint) public etherList;
    House[] public houseList;

    // =================
    // Actors whiteList address
    // =================


    // =================
    // Events declaration
    // =================


    // =================
    // Structs declaration
    // =================
    struct House {
        bytes32 houseAddress;
        address owner;
        bool isForSale;
        uint salePrice;
    }

    // =================
    // Transitions
    // =================
    function from_Initialisation_to_Lifecycle() atStage(Stages.Initialisation) public {
        if (true) {
            stage = Stages.Lifecycle;
        }
    }

    // =================
    // Transactions
    // =================
    function init() atStage(Stages.Initialisation) public { /* Check variables values */

        /* Add implementation behavior here */

        /* Send money, event, etc. here */
        from_Initialisation_to_Lifecycle();
    }

    function register(bytes32 houseAddress) atStage(Stages.Lifecycle) public { /* Check variables values */
        if (houseAddressToId[houseAddress] > 0) {
            revert();
        }

        /* Add implementation behavior here */
        houseAddressToId[houseAddress] = (houseList.length + 1);
        houseList.push(House({
            houseAddress: houseAddress,
            owner: msg.sender,
            isForSale: false,
            salePrice: 0
        }));

        /* Send money, event, etc. here */


    }

    function listForSale(uint amount, bytes32 houseAddress) atStage(Stages.Lifecycle) public {
        uint houseIndex;
        /* Check variables values */
        houseIndex = houseAddressToId[houseAddress];
        if (houseIndex == 0) {
            revert();
        }
        if (houseList[houseIndex].owner != msg.sender) {
            revert();
        }

        /* Add implementation behavior here */
        houseList[(houseIndex - 1)].isForSale = true;
        houseList[(houseIndex - 1)].salePrice = amount;

        /* Send money, event, etc. here */


    }

    function buy(uint amount, address beneficiary, bytes32 houseAddress) payable atStage(Stages.Lifecycle) public {
        address oldOwner;
        uint houseIndex;
        /* Check variables values */
        houseIndex = houseAddressToId[houseAddress];
        if (houseIndex == 0) {
            revert();
        }
        if (!houseList[(houseIndex - 1)].isForSale) {
            revert();
        }
        if (msg.value < houseList[(houseIndex - 1)].salePrice) {
            revert();
        }

        /* Add implementation behavior here */
        oldOwner = houseList[(houseIndex - 1)].owner;
        houseList[(houseIndex - 1)].owner = msg.sender;

        /* Send money, event, etc. here */
        oldOwner.transfer(msg.value);


    }

    // =================
    // State Machine Modifier
    // =================
    modifier atStage(Stages _expectedStage) {
        if (stage == _expectedStage) {
            _;
        }
    }

    // =================
    // Restricting Access by actor Modifier
    // =================


    // =================
    // Utils functions for structs
    // =================
    function findIndexWhereHouseProperty(House[] structArray, bytes32 structProperty, bytes4 operator, bytes32 value) internal pure returns(uint) {
        uint index = 0;

        return index;
    }

    function findStructWhereHouseProperty(House[] structArray, bytes32 structProperty, bytes4 operator, bytes32 value) internal pure returns(House) {
        House memory item = structArray[0];

        return item;
    }
}