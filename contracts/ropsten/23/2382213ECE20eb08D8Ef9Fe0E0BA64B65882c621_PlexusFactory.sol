// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.6.12;

contract PlexusFactory {
    // ======== Construction & Init ========
    address public feeToSetter;
    address payable public implementation;
    address payable public exchangeImplementation;
    address payable public WETH;
    address public plexus;
    address public feeDistributor;
    address public buyback;
    address[] public allPairs;
    address public airdrop;
    uint256 public pairCreateFee = 1e18 * 100;
    address public owner;
    mapping(address => mapping(address => address)) public getPair;
    mapping(address => address) public pairOwner;
    mapping(address => uint256) public fee;
    mapping(address => uint256) public pairOwnerFee;

    // ======== Pool Info ========
    address[] public pools;
    mapping(address => bool) public poolExist;

    // ======== Administration ========

    uint256 public createFee;
    bool public entered;

    constructor(
        address payable _implementation,
        address payable _WETH,
        address payable _plexus,
        address payable _buyback
    ) public {
        implementation = _implementation;
        plexus = _plexus;
        WETH = _WETH;
        feeToSetter = msg.sender;
        buyback = _buyback;
        owner = msg.sender;
    }

    function setImplementation(address payable _newImp) public {
        require(msg.sender == feeToSetter);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function getPairFee(address _pair) external view returns (uint256) {
        return fee[_pair];
    }

    function getPairOwner(address _pair) external view returns (address) {
        return pairOwner[_pair];
    }

    function getPairOwnerFee(address _pair) external view returns (uint256) {
        return pairOwnerFee[_pair];
    }

    function setFeeToSetter(address _feeToSetter) public {
        require(msg.sender == feeToSetter);
        feeToSetter = _feeToSetter;
    }

    function setBuyBack(address _buyback) public {
        require(msg.sender == feeToSetter);
        buyback = _buyback;
    }

    function setFeeDistributor(address _feeDistributor) public {
        require(msg.sender == feeToSetter);
        feeDistributor = _feeDistributor;
    }

    function setAirdrop(address _airdrop) public {
        require(msg.sender == feeToSetter);
        airdrop = _airdrop;
    }

    fallback() external payable {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}