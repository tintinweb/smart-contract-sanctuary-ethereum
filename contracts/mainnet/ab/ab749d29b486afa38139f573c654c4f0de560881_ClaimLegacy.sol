// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './libraries/MerkleProof.sol';
import './libraries/ReentrancyGuard.sol';
import './libraries/Ownable.sol';
import './interfaces/IERC721.sol';

contract ClaimLegacy is Ownable, ReentrancyGuard {
   
    IWallet public firstGen;
    IWallet public secondGen;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public legacyWallet;

    //prices
    uint256 public price = 0 ether; 
    uint8 public maxPerAddress = 1;

    bool public paused = true;
    uint256 private pendingID = 273;

    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    constructor(address _legacyWallet, bytes32 _merkleroot)
        
    {
       
        
        firstGen = IWallet(0x990ce04E035bd6f033B7341FE03639cD40EE0c02);
        secondGen = IWallet(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5);
        legacyWallet = _legacyWallet;
        setMerkleRoot(_merkleroot);
        
    }

    function claim(uint256 quantity, uint256 tokenId, bytes32[] calldata proof) public payable {
        require(!paused, "Claiming is paused");
        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender))), "This address is not whitelisted"
        );

        require(claimed[msg.sender] + quantity <= maxPerAddress, "Max claim per wallet limit already reached");
        require(msg.value >= price * quantity, "Need to send more ETH.");
        
        firstGen.transferFrom(msg.sender, deadWallet, tokenId);
        secondGen.transferFrom(legacyWallet, msg.sender, pendingID);
        pendingID++;
        claimed[msg.sender]++;
        }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
    
    function withdraw() public onlyOwner nonReentrant {
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setFirstGen(address _firstGen) external onlyOwner {
        firstGen = IWallet(_firstGen);
    }

    function setSecondGen(address _secondGen) external onlyOwner {
        secondGen = IWallet(_secondGen);
    }

    function setMaxPerAddress(uint8 _newMax) external onlyOwner {
        maxPerAddress = _newMax;
    }

    function setNextTokenID(uint256 _nextTokenID) external onlyOwner {
        pendingID = _nextTokenID;
    }

    function setMerkleRoot(bytes32 m) public onlyOwner {
        merkleRoot = m;
    }

    function setLegacyWallet(address _legacyWallet) external onlyOwner {
        legacyWallet = _legacyWallet;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IWallet is IERC721 {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './Context.sol';

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}