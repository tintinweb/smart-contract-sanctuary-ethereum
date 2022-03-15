// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./LaunchpadToken.sol";

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

contract NCU_Launchpad {
    string public contract_name;
    address public tokenImplementation;
    uint256 public tax = 2 ether;
    address payable wallet =
        payable(0xc2c7d10B99bf936EffD3cFDD4f5e5f6A6acDDCd3);
    uint256 private counter = 1;

    struct UserDetails {
        address contractOwner;
        address contractAddress;
        string contractName;
        uint256 createdTime;
        uint256 contractId;
    }

    UserDetails[] public userDataArray;

    mapping(address => mapping(string => UserDetails)) public user_data;

    mapping(address => address) public newContractAddress;

    event TokenDeployed(address tokenAddress);

    constructor() {
        tokenImplementation = address(new LaunchpadToken());
        contract_name = "cloning factory";
    }

    function Clone(
        address recipient1,
        string memory _name,
        string memory _symbol,
        uint256 _maxsupply1,
        uint256 _preSaleSupply,
        uint256 _maxPerTrans,
        uint256 _reserve,
        uint256 _price,
        uint256 _presalePrice,
        string memory _baseuri,
        uint256 _maxPerWallet,
        bytes32 _root
    ) public payable {
        address token = Clones.clone(tokenImplementation);

        LaunchpadToken(token).contractDetails(
            _name,
            _symbol,
            _maxsupply1,
            _preSaleSupply,
            _maxPerTrans,
            _reserve,
            _price,
            _presalePrice,
            _baseuri,
            _maxPerWallet,
            _root
        );
        LaunchpadToken(token).initialize(recipient1);
        newContractAddress[recipient1] = token;
        require(tax == msg.value, "enter amount not correct");
        wallet.transfer(msg.value);

        user_data[recipient1][_name] = UserDetails({
            contractOwner: msg.sender,
            contractAddress: token,
            contractName: _name,
            createdTime: block.timestamp,
            contractId: counter
        });

        UserDetails memory _userDataInstance;
        _userDataInstance.contractOwner = msg.sender;
        _userDataInstance.contractAddress = token;
        _userDataInstance.contractName = _name;
        _userDataInstance.createdTime = block.timestamp;
        _userDataInstance.contractId = counter;
        userDataArray.push(_userDataInstance);

        emit TokenDeployed(token);
        counter++;
    }

    function getTotalIndexw(address _owner)
        public
        view
        returns (uint256 total)
    {
        uint256 countt = 0;

        for (uint256 index = 0; index < userDataArray.length; index++) {
            if (userDataArray[index].contractOwner == _owner) {
                countt += 1;
            }
        }
        return countt;
    }

    function getCompleteDataOfOwner(address owner)
        public
        view
        returns (
            address[] memory contractAddresses,
            string[] memory _contractname,
            uint256[] memory contract_time
        )
    {
        // Todo storage todo = todos[_index];
        uint256 dyanamicIndex = 0;

        // return (todo.text, todo.completed);
        address[] memory contractAddressArray = new address[](
            getTotalIndexw(owner)
        );
        string[] memory contractName = new string[](getTotalIndexw(owner));
        uint256[] memory timeStampArray = new uint256[](getTotalIndexw(owner));
        // uint[] memory contractIdArray= new uint [] (getTotalIndexw(owner));
        for (uint256 index = 0; index < userDataArray.length; index++) {
            if (userDataArray[index].contractOwner == owner) {
                contractAddressArray[dyanamicIndex] = userDataArray[index]
                    .contractAddress;
                contractName[dyanamicIndex] = userDataArray[index].contractName;
                timeStampArray[dyanamicIndex] = userDataArray[index]
                    .createdTime;
                //   contractIdArray[dyanamicIndex]=userDataArray[index].contractId;
                dyanamicIndex++;
            }
        }
        return (contractAddressArray, contractName, timeStampArray);
    }

    function getcontractID(address owner)
        public
        view
        returns (uint256[] memory id)
    {
        uint256 dyanamicIndex = 0;
        uint256[] memory contractIdArray = new uint256[](getTotalIndexw(owner));

        for (uint256 index = 0; index < userDataArray.length; index++) {
            if (userDataArray[index].contractOwner == owner) {
                contractIdArray[dyanamicIndex] = userDataArray[index]
                    .contractId;
                dyanamicIndex++;
            }
        }
        return (contractIdArray);
    }
}