/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 */
contract Cloneable {

    /**
        @dev Deploys and returns the address of a clone of address(this
        Created by DeFi Mark To Allow Clone Contract To Easily Create Clones Of Itself
        Without redundancy
     */
    function clone() external returns(address) {
        return _clone(address(this));
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function _clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

}
/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IStaking {
    function __init__(
        address nft,
        address rewardToken,
        uint256 lockTime,
        string calldata name,
        string calldata symbol,
        address lockTimeSetter
    ) external;
}

interface IHasTotalSupply {
    function totalSupply() external view returns (uint256);
}

contract NFTStakingGenerator is Ownable {

    /**
        Proxy Implementation Through Which NFT Staking Contracts Are Generated
     */
    address public proxyImplementation;

    /**
        Project Structure
     */
    struct Project {
        string name;
        address nft;
        address stakingProxy;
        uint256 minID;
        uint256 maxID;
    }

    /**
        Staking Proxy => Project Struct
     */
    mapping ( address => Project ) public stakingToProject;
    
    /**
        NFT => Project Struct
     */
    mapping ( address => Project ) public nftToStaking;

    /**
        List Of All Staking Proxies
     */
    address[] public allProjects;

    /**
        True If User Can Create Staking Proxies, False Otherwise
     */
    mapping ( address => bool ) public canCreateStakingContracts;
    modifier canCreate() {
        require(
            canCreateStakingContracts[msg.sender] || msg.sender == this.getOwner(),
            'Invalid Permissions'
        );
        _;
    }

    constructor(address implementation) {
        canCreateStakingContracts[msg.sender] = true;
        proxyImplementation = implementation;
    }

    function setMinMax(address project, uint256 newMin, uint256 newMax) external onlyOwner {
        stakingToProject[project].minID = newMin;
        stakingToProject[project].maxID = newMax;

        nftToStaking[stakingToProject[project].nft].minID = newMin;
        nftToStaking[stakingToProject[project].nft].maxID = newMax;
    }

    function givePermissionToCreateStakingContracts(address user, bool isAllowed) external onlyOwner {
        canCreateStakingContracts[user] = isAllowed;
    }

    function setNewImplementation(address newProxyImplementation) external onlyOwner {
        proxyImplementation = newProxyImplementation;
    }

    function createWithImplementation(
        address nft, 
        string calldata name,
        string calldata symbol,
        address implementation,
        address rewardToken,
        uint256 lockTime,
        uint256 min,
        uint256 max,
        address owner
    ) external canCreate returns (address) {
        return _create(nft, name, symbol, implementation, rewardToken, lockTime, min, max, owner);
    }

    function create(
        address nft, 
        string calldata name,
        string calldata symbol,
        address rewardToken,
        uint256 lockTime,
        uint256 min,
        uint256 max,
        address owner
    ) external canCreate returns (address) {
        return _create(nft, name, symbol, proxyImplementation, rewardToken, lockTime, min, max, owner);
    }

    function _create(
        address nft, 
        string calldata name, 
        string calldata symbol,
        address implementation, 
        address rewardToken, 
        uint256 lockTime,
        uint256 min,
        uint256 max,
        address owner
    ) internal returns (address project) {

        project = Cloneable(implementation).clone();

        IStaking(project).__init__(nft, rewardToken, lockTime, name, symbol, owner);

        Project memory newProject = Project({
            name: name,
            nft: nft,
            stakingProxy: project,
            minID: min,
            maxID: max
        });

        stakingToProject[project] = newProject;
        nftToStaking[nft] = newProject;

        allProjects.push(project);
    }
    

    function fetchAllProjects() external view returns (address[] memory) {
        return allProjects;
    }

    function fetchAllProjectsAndNames() external view returns (address[] memory, string[] memory) {

        uint len = allProjects.length;
        string[] memory names = new string[](len);
        for (uint i = 0; i < len;) {
            names[i] = stakingToProject[allProjects[i]].name;
            unchecked {
                ++i;
            }
        }

        return (allProjects, names);
    }

    function fetchAllProjectsAndNamesAndNFTs() external view returns (address[] memory, string[] memory, address[] memory) {

        uint len = allProjects.length;
        string[] memory names = new string[](len);
        address[] memory nfts = new address[](len);
        for (uint i = 0; i < len;) {
            names[i] = stakingToProject[allProjects[i]].name;
            nfts[i] = stakingToProject[allProjects[i]].nft;
            unchecked {
                ++i;
            }
        }

        return (allProjects, names, nfts);
    }

    function fetchAllProjectsAndNamesNFTsMinsMaxs() external view returns (address[] memory, string[] memory, address[] memory, uint256[] memory, uint256[] memory) {

        uint len = allProjects.length;
        string[] memory names = new string[](len);
        address[] memory nfts = new address[](len);
        uint256[] memory mins = new uint256[](len);
        uint256[] memory maxs = new uint256[](len);
        for (uint i = 0; i < len;) {
            names[i] = stakingToProject[allProjects[i]].name;
            nfts[i] = stakingToProject[allProjects[i]].nft;
            mins[i] = stakingToProject[allProjects[i]].minID;
            maxs[i] = stakingToProject[allProjects[i]].maxID;
            unchecked {
                ++i;
            }
        }

        return (allProjects, names, nfts, mins, maxs);
    }

    function fetchAllProjectsAndNamesNFTsMinTotals() external view returns (address[] memory, string[] memory, address[] memory, uint256[] memory, uint256[] memory) {

        uint len = allProjects.length;
        string[] memory names = new string[](len);
        address[] memory nfts = new address[](len);
        uint256[] memory mins = new uint256[](len);
        uint256[] memory maxs = new uint256[](len);
        for (uint i = 0; i < len;) {
            names[i] = stakingToProject[allProjects[i]].name;
            nfts[i] = stakingToProject[allProjects[i]].nft;
            mins[i] = stakingToProject[allProjects[i]].minID;
            maxs[i] = IHasTotalSupply(stakingToProject[allProjects[i]].nft).totalSupply();
            unchecked {
                ++i;
            }
        }

        return (allProjects, names, nfts, mins, maxs);
    }

}