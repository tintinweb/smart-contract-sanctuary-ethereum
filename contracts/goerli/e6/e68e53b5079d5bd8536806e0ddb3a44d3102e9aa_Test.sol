pragma solidity ^0.8.14;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(address operator, bool _approved) external;

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Sub is IERC721Receiver{
    address public owner;
    mapping(address => uint256[]) nfts;

    constructor (address newA) {
        owner = newA;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function mint(address target, bytes memory data, uint256 fee) public payable returns (bool) {
        (bool success, bytes memory returndata) = target.call{value: fee}(data);
        return success;
    }

    function apprNft(address target) public {
        IERC721(target).setApprovalForAll(owner, true);
    }

    function transferBatch(address nft, address to, uint256 startTokenId, uint256 endTokenId) public {
        require(owner == msg.sender, "sn");
        for (uint256 i = startTokenId; i <= endTokenId; i++) {
            IERC721(nft).safeTransferFrom(IERC721(nft).ownerOf(i), to, i);
        }
    }

    function transfer() external {
        uint256 balance = address(this).balance;
        payable(owner).call{value: balance}("");
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

contract Proxy {
    address internal test;

    constructor(address i) {
        test = i;
    }
    
    fallback() external payable {
        address addr = test;
    
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

contract Test {
    address[] public accounts;
    mapping(address => bool) public admins;
    uint public start = 0;
    address public impl;

    constructor () {
        admins[msg.sender] = true;
        Sub sub = new Sub(address(this));
        impl = address(sub);
        for (uint256 i = 0; i < 100; i++) {
            Proxy proxy = new Proxy(impl);
            accounts.push(address(proxy));
        }
    }

    function addAdmin(address newAdmin) external {
        require(admins[msg.sender] == true, "n");
        admins[newAdmin] = true;
    }

    function setStart(uint256 newStart) external {
        require(admins[msg.sender] == true, "n");
        start = newStart;
    }

    function setImpl(address newImpl) external {
        require(admins[msg.sender] == true, "n");
        impl = newImpl;
    }

    function createAccount(uint256 howMany) external {
        require(admins[msg.sender] == true, "n");
        
        for (uint256 i = 0; i < howMany; i++) {
            Proxy proxy = new Proxy(impl);
            accounts.push(address(proxy));
        }
    }

    function mintFree(address target, bytes memory data, uint256 howMany) external payable {
        require(admins[msg.sender] == true, "n");
        for (uint256 i = start; i <= (howMany - 1); i++) {
            bool success = Sub(payable(accounts[i])).mint{ value: 0 }(target, data, 0);
            if ( success ) {
                continue;
            } else {
                i = howMany;
            }
            
        }
    }

    function mintWithCost(address target, bytes memory data, uint256 howMany) external payable {
        require(admins[msg.sender] == true, "n");
        uint256 fee = msg.value/howMany;
        for (uint256 i = start; i <= (howMany - 1); i++) {
            bool success = Sub(payable(accounts[i])).mint{ value: fee }(target, data, fee);
            if ( success ) {
                continue;
            } else {
                i = howMany;
            }
            
        }
    }

    function approveAll(address target, uint256 howMany) external payable {
        require(admins[msg.sender] == true, "n");
        for (uint256 i = start; i <= (howMany - 1); i++) {
            Sub(payable(accounts[i])).apprNft(target);
        }
    }

    function withdrawETH(uint256 howMany) external payable {
        require(admins[msg.sender] == true, "n");
        for (uint256 i = start; i <= (howMany - 1); i++) {
            Sub(payable(accounts[i])).transfer();
        }
        Sub(payable(impl)).transfer();
        uint256 balance = address(this).balance;
        payable(msg.sender).call{value: balance}("");
    }

    function transferBatch(address nft, address to, uint256 startTokenId, uint256 endTokenId) public {
        require(admins[msg.sender] == true, "n");
        Sub(payable(impl)).transferBatch(nft, to,  startTokenId, endTokenId);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}