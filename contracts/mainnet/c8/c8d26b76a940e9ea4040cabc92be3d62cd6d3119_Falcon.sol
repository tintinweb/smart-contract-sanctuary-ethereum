/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

//SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

// Create your NFT Project on Uminty.com


interface Ifactory {
    function createContractViaFalcon(uint256 _projectID, address _creator, string memory _name, string memory _symbol, uint256 _maxTokens, uint256 _reservedTokens) external;

}

contract Falcon is Ownable {

    uint256 private balanceOwner;
    uint256 public shareAfterPlatformFee;
    uint256 public shareAfterSoldOutFee;
    uint256 public totalShares;
    address public factoryContract;
    address private ownerM;

    uint256 public maxDays;
    uint256 public maxDaysRenewal;
    uint256 public minPrice;
    bool public paused;


    struct Project {
        uint256 projectID;
        address creator;
        uint256 projectBalance;
        uint256 maxTokens;
        uint256 reservedTokens;
        uint256 price;
        bool whitelistEnabled;
        uint256 maxPublicPremint;
        uint256 maxWhitelistPremint;
        uint256 presoldTokens;
        uint256 startDate;
        uint256 endDate;
        mapping(address => uint256) funderTokens;
        mapping(address => uint256) pledgeOf;

    }

    //number of projects
    uint256 public numProject;
    //ID to project
    mapping(uint256 => Project) public projects;

    mapping(address => uint256[]) public creatorProjects;

    mapping(uint256 => address) public contractOfProject;

    mapping(uint256 => uint256) private collectedFees;

    mapping(uint256 => bool) public contractMintedByProject;

    mapping(uint256 => bool) public endDateRenewed;

    mapping(uint256 => bytes32) public merkleRootByProject;

    event newProject(uint256 projectID, address creator, uint256 maxTokens, uint256 reservedTokens, uint256 price, bool whitelistEnabled, uint256 maxPublicPremint, uint256 maxWhitelistPremint, uint256 endDate);
    event premint(uint256 projectID, uint256 numberOfTokens, address buyer, uint256 presoldTokens);
    event contractCreated(address addressContract, address creator, string name, string symbol, uint256 maxTokens, uint256 reservedTokens, uint256 projectID);
    event priceUpdated(uint256 projectID, uint256 newPrice);
    event newEndDate(uint256 projectID, uint256 newEndDate);
    event maxPublicPremintUpdated(uint256 projectID, uint256 newMaxPP);
    event maxWhitelistPremintUpdated(uint256 projectID, uint256 newMaxWP);
    event whitelistEnabledUpdated(uint256 projectID, bool value);


    modifier notPaused() {
        require(paused == false);
        _;
    }

    modifier onlyOwnerM() {
        require(msg.sender == ownerM);
        _;
    }


    constructor(uint256 _shareUser, uint256 _shareCreator, uint256 _shares, uint256 _days, uint256 _maxDaysRenewal, address _ownerM) {
        setShares(_shareUser, _shareCreator, _shares);
        maxDays = _days;
        maxDaysRenewal = _maxDaysRenewal;
        ownerM = _ownerM;
    }


    function createProject(uint256 _maxTokens, uint256 _reservedTokens, uint256 _priceETH, bool _whitelistEnabled, uint256 _maxPublicPremint, uint256 _nbOfDays) public notPaused returns (uint projectID) {
                            
                            require(maxDays >= _nbOfDays && _nbOfDays != 0, "Wrong number of Days");
                            require(_priceETH >= minPrice, "Price should be > minPrice");
                            require(_reservedTokens > 0 && _reservedTokens < _maxTokens, "min 1 reserved tokens");
                            
                            projectID = numProject++;
                            Project storage p = projects[projectID];

                            p.projectID = projectID;
                            p.creator = msg.sender;
                            p.maxTokens = _maxTokens;
                            p.reservedTokens = _reservedTokens;
                            p.price = _priceETH;
                            p.whitelistEnabled = _whitelistEnabled;
                            p.maxPublicPremint = _maxPublicPremint;
                            p.maxWhitelistPremint = 5;
                            p.startDate = block.timestamp;
                            p.endDate = block.timestamp + (_nbOfDays * 1 days);

                            creatorProjects[msg.sender].push(projectID);
                            emit newProject(p.projectID, p.creator, p.maxTokens, p.reservedTokens, p.price, p.whitelistEnabled, p.maxPublicPremint, p.maxWhitelistPremint, p.endDate);
    }
    
    
    
    function publicPremint(uint256 _projectID, uint256 _numberOfTokens) public payable {

                Project storage projectToFund = projects[_projectID];
                uint256 amount = projectToFund.price * _numberOfTokens;
                uint256 pledge = amount * shareAfterPlatformFee / totalShares;
                
                require(!projectToFund.whitelistEnabled, "The whitelist sale is enabled");
                require(msg.sender != projectToFund.creator, "You are the creator");
                require(msg.value >= amount, "Wrong amount of ETH");
                require(projectToFund.funderTokens[msg.sender] + _numberOfTokens <= projectToFund.maxPublicPremint, "You cannot buy more tokens with this wallet");
                require(projectToFund.presoldTokens + _numberOfTokens <= projectToFund.maxTokens - projectToFund.reservedTokens, "Not Enough Tokens to sale");
                require(block.timestamp <= projectToFund.endDate, "This project is expired");


                projectToFund.presoldTokens += _numberOfTokens;
                projectToFund.funderTokens[msg.sender] += _numberOfTokens;
                projectToFund.pledgeOf[msg.sender] += pledge;
                projectToFund.projectBalance += amount;
                collectedFees[_projectID] += amount - pledge;
                balanceOwner += msg.value - pledge;

                emit premint(_projectID, _numberOfTokens, msg.sender, projectToFund.presoldTokens);

    }


    function WhitelistPremint(uint256 _projectID, uint256 _numberOfTokens, bytes32[] calldata _merkleProof) public payable {

                Project storage projectToFund = projects[_projectID];
                uint256 amount = projectToFund.price * _numberOfTokens;
                uint256 pledge = amount * shareAfterPlatformFee / totalShares;
                
                require(projectToFund.whitelistEnabled, "The whitelist sale is not enabled");
                require(msg.sender != projectToFund.creator, "You are the creator");
                require(isWhitelisted(_projectID, _merkleProof), "You are not whitelisted");
                require(projectToFund.maxWhitelistPremint >= projectToFund.funderTokens[msg.sender] + _numberOfTokens, "You already preminted");
                require(msg.value >= amount, "Wrong amount of ETH");
                require(projectToFund.presoldTokens + _numberOfTokens <= projectToFund.maxTokens - projectToFund.reservedTokens, "Not Enough Tokens to sale");
                require(block.timestamp <= projectToFund.endDate, "This project is expired");


                projectToFund.presoldTokens += _numberOfTokens;
                projectToFund.funderTokens[msg.sender] += _numberOfTokens;
                projectToFund.pledgeOf[msg.sender] += pledge;
                projectToFund.projectBalance += amount;
                collectedFees[_projectID] += amount - pledge;
                balanceOwner += msg.value - pledge;

                emit premint(_projectID, _numberOfTokens, msg.sender, projectToFund.presoldTokens);

    }

    function isWhitelisted(uint256 _projectID, bytes32[] calldata _merkleProof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
         return MerkleProof.verify(_merkleProof, merkleRootByProject[_projectID], leaf);
    }

    
    function getpledge(uint256 _ID, address _funder) public view returns(uint256) {
        return projects[_ID].pledgeOf[_funder];
    }


    function getRefund (uint256 _projectID) public {

        Project storage p = projects[_projectID];

        require(p.presoldTokens < p.maxTokens - p.reservedTokens, "This project is succesful");
        require(block.timestamp > p.endDate, "This project is fundraising");
        require(p.pledgeOf[msg.sender] > 0, "No Funds");

        uint256 amount = p.pledgeOf[msg.sender];
        p.pledgeOf[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

    }

    function createContract(uint256 _projectID, string memory _name, string memory _symbol) public {
        Project storage p = projects[_projectID];
        
        require(p.presoldTokens >= p.maxTokens - p.reservedTokens, "This project is not fundraised");
        require(p.creator == msg.sender, "You are not the project creator");
        

         Ifactory(factoryContract).createContractViaFalcon(_projectID, msg.sender, _name, _symbol, p.maxTokens, p.reservedTokens);

        emit contractCreated(contractOfProject[_projectID], msg.sender, _name, _symbol, p.maxTokens, p.reservedTokens, p.projectID);
    }

    function setAddrContractViaFactory(uint256 _projectID, address _addrContract) external {
        require(msg.sender == factoryContract, "You are not allowed");
        contractOfProject[_projectID] = _addrContract;
    }

    function setContractMintedViaFactory(uint256 _projectID, bool _value) external {
        require(msg.sender == factoryContract, "You are not allowed");
        contractMintedByProject[_projectID] = _value;
    }


    function creatorPayout (uint256 _projectID) public {

        Project storage p = projects[_projectID];
        
        require(p.presoldTokens >= p.maxTokens - p.reservedTokens, "This project is not fundraised");
        require(p.creator == msg.sender, "You are not the project creator");
        require(contractMintedByProject[_projectID] == true, "You need to mint the contract first");
        require(p.projectBalance > 0, "No funds");
        
        uint256 amount = p.projectBalance * shareAfterSoldOutFee / totalShares;
        uint256 fees = p.projectBalance - amount;
        
        if (fees > collectedFees[_projectID]) {
            balanceOwner += fees - collectedFees[_projectID];
        }

        p.projectBalance = 0;


        payable(p.creator).transfer(amount);

    }


    function getListCreatorProjects(address _address) public view returns(uint256 [] memory) {
        return creatorProjects[_address];
    }

    function getNumberOfTokensByFunder(uint256 _projectID, address _funder) public view returns(uint256) {
        return projects[_projectID].funderTokens[_funder];
    }

    function getTokensLeft(uint256 _projectID) public view returns(uint256) {
        uint256 tokensLeft = projects[_projectID].maxTokens - projects[_projectID].reservedTokens - projects[_projectID].presoldTokens;
        return tokensLeft;
    }

// CREATOR ONLY

    function setPrice(uint256 _projectID, uint256 _newPrice) public {
        require(msg.sender == projects[_projectID].creator, "You are not the creator");
        require(_newPrice >= minPrice, "Price should be > minPrice");
        projects[_projectID].price = _newPrice;
        
        emit priceUpdated(_projectID, projects[_projectID].price);
    }

    function setNewDate(uint256 _projectID, uint256 _nbOfDays) public {
        require(msg.sender == projects[_projectID].creator, "You are not the creator");
        require(endDateRenewed[_projectID] == false, "End date already Renewed");
        require(projects[_projectID].presoldTokens < projects[_projectID].maxTokens - projects[_projectID].reservedTokens, "This project is fundraised");
        require(projects[_projectID].endDate >= block.timestamp, "Expired");
        require(maxDaysRenewal >= _nbOfDays && _nbOfDays != 0, "Wrong number of Days");
        
        projects[_projectID].endDate = projects[_projectID].endDate + (_nbOfDays * 1 days);
        endDateRenewed[_projectID] = true;

        emit newEndDate(_projectID, projects[_projectID].endDate);
    }

    function setMaxPublicPremint(uint256 _projectID, uint256 _newMaxPremint) public {
        require(msg.sender == projects[_projectID].creator, "You are not the creator");
        projects[_projectID].maxPublicPremint = _newMaxPremint;

        emit maxPublicPremintUpdated(_projectID, projects[_projectID].maxPublicPremint);  
    }

    function setMaxWhitelistPremint(uint256 _projectID, uint256 _newMaxPremint) public {
        require(msg.sender == projects[_projectID].creator, "You are not the creator");
        projects[_projectID].maxWhitelistPremint = _newMaxPremint;

        emit maxWhitelistPremintUpdated(_projectID, projects[_projectID].maxWhitelistPremint); 
    }

    function setWhitelistEnabled(uint256 _projectID, bool _value) public {
        require(msg.sender == projects[_projectID].creator, "You are not the creator");
        projects[_projectID].whitelistEnabled = _value;

        emit whitelistEnabledUpdated(_projectID, projects[_projectID].whitelistEnabled);
    }

    function setRootWhitelist(uint256 _projectID, bytes32 _merkleRoot) public {
        require(msg.sender == projects[_projectID].creator, "You are not the creator");
        merkleRootByProject[_projectID] = _merkleRoot;
    }


    // ADMIN
        // max fee: 20%
     function setShares(uint256 _shareUser, uint256 _shareCreator, uint256 _shares) public onlyOwner {
         uint256 feeU = 1 ether * _shareUser / _shares;
         uint256 feeC = 1 ether * _shareCreator / _shares;
         uint256 maxfee = 1 ether * 8000 / 10000;
         require(feeC >= maxfee, "max feeC");
         require(feeU >= feeC, "max feeU");
         shareAfterPlatformFee = _shareUser;
         shareAfterSoldOutFee = _shareCreator;
         totalShares = _shares;
     }

     function getownerM() public onlyOwner view returns(address) {
        return ownerM;
     }

     function setFactoryContract(address _factory) public onlyOwner {
         factoryContract = _factory;
     }

     function setMinPrice(uint256 _minPrice) public onlyOwner {
        minPrice = _minPrice;
     }

     function getCollectedFees(uint256 _projectID) public onlyOwnerM view returns(uint256) {
         return collectedFees[_projectID];
     }

     function getBalanceOwner() public onlyOwnerM view returns(uint256) {
         return balanceOwner;
     }

     function setMaxDays(uint256 _numberOfDays, uint256 _maxDaysRenewal) public onlyOwner {
         maxDays = _numberOfDays;
         maxDaysRenewal = _maxDaysRenewal;
     }

     function withdraw(address _wallet, uint256 _amount) public onlyOwnerM {
         require(_amount <= balanceOwner, "Not enough funds");
        balanceOwner -= _amount;

        payable(_wallet).transfer(_amount);
     }

     function setOwnerM(address _wallet) public onlyOwnerM {
         require(_wallet != address(0), "new owner is the zero address");
         ownerM = _wallet;
     }

     function setPaused(bool _value) public onlyOwner {
         paused = _value;
     }

    // Emergency only
     function modifyContractMinted(uint256 _projectID, bool _value) public onlyOwner {
         contractMintedByProject[_projectID] = _value;
     }

     function modifyEndDate(uint256 _projectID, uint256 _date) public onlyOwner {
         projects[_projectID].endDate = _date;
     }

     function modifyMaxTokens(uint256 _projectID, uint256 _maxSupply) public onlyOwner {
         projects[_projectID].maxTokens = _maxSupply;
     }

     function emergencyCreatorPayOut(uint256 _projectID) public onlyOwner {
        Project storage p = projects[_projectID];
        
        require(p.presoldTokens >= p.maxTokens - p.reservedTokens, "This project is not fundraised");
        require(contractMintedByProject[_projectID] == true, "You need to mint the contract first");
        require(p.projectBalance > 0, "No funds");
        
        uint256 amount = p.projectBalance - collectedFees[_projectID];

        p.projectBalance = 0;


        payable(p.creator).transfer(amount);
     }



}