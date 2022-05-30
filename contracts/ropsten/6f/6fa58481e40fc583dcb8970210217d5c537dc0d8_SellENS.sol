/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity >=0.4.16 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

contract SellENS {

    IERC721 ens;

    mapping (bytes32=>address) Sale;
    mapping (bytes32=>address) Beneficiary;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    address private owner ;

    constructor() {
        owner=msg.sender;
        ens=IERC721(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    }

    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function proposeSale(bytes32 hash) public {
          proposeSale(hash,msg.sender);
    }

    function proposeSale(bytes32 hash,address beneficiary) public {
        //hash is keccak265 of ENSName (without .eth extension)+allowed purchasing wallet+token contract+token value
        //0 in purchasing wallet allows anyone to purchase the name
        //token contract = 0 means ETHER and not token
        //Example: propose sale of ens.eth to wallet 0xDEAD only for 0.1eth needs hash=keccak256(abi.encodePacked(ens,0xDEAD,0,100000000000000000))
	require(ens.isApprovedForAll(msg.sender,address(this)));
	Sale[hash]=msg.sender;
	Beneficiary[hash]=beneficiary;
    }

    function cancelSale(bytes32 hash) public {
	require(Sale[hash]==msg.sender);
	Sale[hash]=address(0);
        Beneficiary[hash]=address(0);
    }

    function calculateHash(string memory ensNAME,address buyer,address token,uint value) public view returns(bytes32) {
	return(keccak256(abi.encodePacked(ensNAME,buyer,token,value)));
    }


    function verifySale(string memory ensNAME,address token,uint value) public view returns(bool,address) {
	bytes32 hash=keccak256(abi.encodePacked(ensNAME,msg.sender,token,value));
        address seller=Sale[hash];
        address beneficiary=Beneficiary[hash];
        if(seller==address(0)) {
            bytes32 hash2=keccak256(abi.encodePacked(ensNAME,address(0),token,value));
            seller=Sale[hash2];
            beneficiary=Beneficiary[hash2];
        }
	return (seller!=address(0),beneficiary);
    }

    function purchase(string memory ensNAME,address token,uint value,address buyer) public payable {
	bytes32 hash=keccak256(abi.encodePacked(ensNAME,msg.sender,token,value));
        address seller=Sale[hash];
        address payable beneficiary=payable(Beneficiary[hash]);
        if(seller==address(0)) {
	    bytes32 hash2=keccak256(abi.encodePacked(ensNAME,address(0),token,value));
            seller=Sale[hash2];
            beneficiary=payable(Beneficiary[hash2]);
	}
        uint256 ens_token=uint256(keccak256(abi.encodePacked(ensNAME)));
	require(seller!=address(0) && ens.ownerOf(ens_token)==seller && ens.isApprovedForAll(seller,address(this)));
	if(token==address(0)) {
	    //Sale is in ETHER
            require(value<=msg.value);
	    beneficiary.transfer(value);
	} else {
	    ERC20 erc=ERC20(token);
	    require(erc.allowance(msg.sender,address(this))>=value && erc.balanceOf(msg.sender)>=value);
	    erc.transferFrom(msg.sender,beneficiary,value);
	}
	ens.transferFrom(seller, buyer, ens_token);  
    }
}


interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC721 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}