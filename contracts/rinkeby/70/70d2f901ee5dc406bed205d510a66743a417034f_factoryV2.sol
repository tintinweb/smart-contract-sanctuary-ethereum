/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721{
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface Ilink {
    function initialize(address _nft, address _userA, address _userB, uint256 _idA, uint256 _idB, uint256 _lockDays) external;
    function userB() external returns(address);
    function idB() external returns(uint256);
    function NFT() external returns(address);
    function agree() external;
}

contract Ownable{
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external {
        require(_owner != address(0), "owner address cannot be 0");
        owner = _owner;
    }
}

contract Initialize {
    bool internal initialized;
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}


contract Config is Ownable{
    uint256 public minLockDay;
    uint256 public maxLockDay;
    address public nftLink;
    mapping(address => bool) public allowedNFT;
    mapping(address => bool) public isLink;
    uint256 public totalLink;

    function setNftLink(address link) external onlyOwner {
        require(link != address(0), "link address cannot be 0");
        nftLink = link;
    }

    function setLockDay(uint256 min, uint256 max) external onlyOwner {
        (minLockDay, maxLockDay) = (min, max);
    }

    function addNFT(address nft) external onlyOwner {
        require(nft != address(0), "nft address cannot be 0");
        allowedNFT[nft] = true;
    }

    function removeNFT(address nft) external onlyOwner {
        allowedNFT[nft] = false;
    }
}

contract CloneFactory {
    function _clone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract factoryV2 is Ownable, Config, Initialize, CloneFactory {
    event Create(address from, address target, address nft);

    function initialize(uint256 min, uint256 max,address link) noInit public {
        (minLockDay, maxLockDay, link) = (min, max, link);
    }

    // function agree(address _link) external{
    //     require(isLink[_link], "only link");
    //     require(msg.sender == Ilink(_link).userB(), "only userB");
       
    //     IERC721(Ilink(_link).NFT()).transferFrom(Ilink(_link).userB(), _link, Ilink(_link).idB());
    //     Ilink(_link).agree();
    // }

    function getToken(address nft, address user, uint256 id) external{
         require(isLink[msg.sender], "only Link");
         IERC721(nft).transferFrom(user, msg.sender, id);
    }

    function createLink(address nft, address target, uint256[] calldata tokenId, uint256 lockDays) external{
        bool isFullLink = msg.sender == target;
        require(target != address(0),"target cannot be 0");
        require(allowedNFT[nft], "nft invalid");
        require(lockDays > minLockDay && lockDays <= maxLockDay, "lockDays invalid");
        IERC721 NFT = IERC721(nft);
        if (isFullLink){
            //fullLink
            require(tokenId.length == 2 ,"fullLink need provide 2 tokenIds");
            require(tokenId[0] != 0 && tokenId[1] != 0, "tokenId invalid");
            require(tokenId[0] != tokenId[1], "tokenId cannot be the same");
            require(NFT.ownerOf(tokenId[0]) == msg.sender && NFT.ownerOf(tokenId[1]) == msg.sender,"not token owner");
            require(NFT.isApprovedForAll(msg.sender, address(this)) || (NFT.getApproved(tokenId[0]) == address(this) && NFT.getApproved(tokenId[1]) == address(this)),"not Approved");
        }else{
            //normalLink
            require(tokenId.length == 1 , "normalLink need provide 1 tokenId");
            require(tokenId[0] != 0, "tokenId invalid");
            require(NFT.ownerOf(tokenId[0]) == msg.sender,"not token owner");
            require(NFT.isApprovedForAll(msg.sender, address(this)) || NFT.getApproved(tokenId[0]) == address(this),"not Approved");
        }

        //create contract
        Ilink link = Ilink(_clone(nftLink));
        totalLink++;
        isLink[address(link)] = true;
        uint256 idB = isFullLink ? tokenId[1] : 0;


        NFT.transferFrom(msg.sender, address(link), tokenId[0]);
        if (isFullLink) NFT.transferFrom(msg.sender, address(link), tokenId[1]);

        //set link info
        link.initialize(nft, msg.sender, target, tokenId[0], idB, lockDays);
        emit Create(msg.sender, target, nft);
    }
}