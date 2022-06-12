/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/*
*
*                                                  🚬
*                                               🚬🚬
*                                             🚬🚬
*                                           🚬🚬
*                                            🚬🚬
*                                             🚬🚬
* 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬
*           CryptoPunks 5th Birthday           🚬🚬🚬
*             Gift from tycoon.eth            🚬🚬🚬
* 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬
*
* This contract does not read/write into the CryptoPunks contract.
* It does not require any approvals or permissions.
* All distribution is done using a Merkle tree from a snapshot on 10th of
* June 2022.
*
* Simply claim from the address where you had a punk on 10th of June 2022.
* (Your punk does not have to be in the wallet while you claim, it only had
* to be there in the 10th of June)
*
* Claim at: https://thedaonft.eth.limo/punks.html
*
* Only 500 items in the inventory!
*
* What is it? It's a NFT collection created by me, tycoon.eth around November
* 2021.
*
* Like most of you, I've been fascinated with NFTs, so I got curious &
* creative.
* I'm also fascinated about the TheDAO, so I've put the two together,
* See more details at thedaonft.eth.limo
* After completion, the project was handed over to the "DAO Museum Multisig",
* so I don't own it by myself, but as of writing, I'm still one of the signers
* on the multisig and I can change the website.
*
* I mostly give these away to friends, and it's a great conversation starter!
*
* Each NFT has 1 DAO token inside, which is worth 0.01 ETH
* You can burn the NFT to get the DAO token back. (The NFT can be restored,
* but it will cost 4 DAO to restore)
* 1 DAO will always be worth 0.01 ETH because there is a smart contract that
* can instantly redeem 0.01 ETH for every DAO you have.
*
* Oh, if you have multiple addresses and received multiple pieces, consider
* giving a spare to someone who missed out <3
*
* The Curator will shutdown this contract if there are no new claims for
* longer than 30 days.
*
* Happy 5th Birthday CryptoPunks!
*
*
* deployed with:
* _THEDAO 0xbb9bc244d798123fde783fcc1c72d3bb8c189413
* _THENFT 0x79a7d3559d73ea032120a69e59223d4375deb595
*/


contract TheGift {

    IERC20 private immutable theDAO;
    ITheNFT private immutable theNFT;
    mapping(address => uint256) public claims;
    address payable public curator;
    bytes32 public root;
    mapping (uint256 => batch) private inventory;
    uint256 public curBatch;
    uint256 public nextBatch;
    event Claim(address);
    struct batch {
        uint256 end;
        uint256 progress;
    }

    constructor(address _theDAO, address _theNFT) {
        curator = payable(msg.sender);
        theDAO = IERC20(_theDAO);
        theNFT = ITheNFT(_theNFT);
        theDAO.approve(_theNFT, type(uint256).max); // approve TheNFT to spend our DAO tokens on contract's behalf
    }

    modifier onlyCurator {
        require(
            msg.sender == curator,
            "only curator can call this"
        );
        _;
    }

    function setRoot(bytes32 _r) external onlyCurator {
        root = _r;
    }

    function setCurator(address _a) external onlyCurator {
        curator = payable(_a);
    }

    function bulkMint(uint256 rounds) external onlyCurator {
        unchecked {
            uint256[] memory ret = theNFT.getStats(address(this));
            batch storage b = inventory[nextBatch];
            b.progress = 1800-ret[2];
            for (uint256 i = 0; i < rounds; i++) {
                theNFT.mint(100);
            }
            b.end = 1800-ret[2]+100;
            nextBatch++;
        }
    }

    function shutdown(uint256[] calldata _ids, bool _destruct) external onlyCurator {
        for (uint256 i; i < _ids.length; i++) {
            theNFT.transferFrom(address(this), msg.sender, _ids[i]);
        }
        if (theDAO.balanceOf(address(this))>0) {
            theDAO.transfer(msg.sender, theDAO.balanceOf(address(this)));
        }
        if (_destruct) {
            selfdestruct(curator);
        }
    }

    function verify(
        address _to,
        bytes32 _root,
        bytes32[] memory _proof
    ) public pure returns (bool) {
        bytes32 computedHash = keccak256(abi.encodePacked(_to)); // leaf
        for (uint256 i = 0; i < _proof.length; ) {
            bytes32 proofElement = _proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            unchecked { i++; }
        }
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == _root;
    }

    function claim(address _to, bytes32[] memory _proof) external {
        require(claims[msg.sender] == 0, "already claimed");
        require(verify(_to, root, _proof), "invalid proof");
        require(theNFT.balanceOf(address(this)) > 0, "no nfts available");
        uint256 id;
        batch storage b = inventory[curBatch];
        id = b.progress;
        theNFT.transferFrom(address(this), _to, id); // will fail if already claimed
        emit Claim(_to);
        claims[_to] = id;
        unchecked { b.progress++; }
        if (b.progress >= b.end) {
            unchecked { curBatch++; }
        }
    }

    function getStats(address _user,  bytes32[] memory _proof) external view returns(uint256[] memory) {
        uint[] memory ret = new uint[](10);
        ret[0] = theNFT.balanceOf(_user);
        ret[1] = theNFT.balanceOf(address(this));
        if (verify(_user, root, _proof)) {
            ret[2] = 1;
        }
        ret[3] = curBatch;
        ret[4] = nextBatch;
        batch storage b = inventory[curBatch];
        ret[5] = b.progress;
        return ret;
    }
}



/*
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * 0xTycoon was here
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
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
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4);
}
interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


interface ITheNFT is IERC721 {
    function mint(uint256 i) external;
    function getStats(address user) external view returns(uint256[] memory);
}