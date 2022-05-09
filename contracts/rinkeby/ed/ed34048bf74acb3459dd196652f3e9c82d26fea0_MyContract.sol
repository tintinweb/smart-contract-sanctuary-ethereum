/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC721{
    function ownerOf(uint256 tokenId) external view returns(address);
    function safeTransferFrom(address from , address to ,uint256 tokenId ) external;
    function setApprovalForAll(address operator  , bool approved) external;
}

interface IOsProxy{
    function registerProxy() external;
    function proxies(address _addr) external view returns(address);
}

interface IOsTrans{
    function atomicMatch_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) external payable;
}
contract Base{
    // 充值
    function deposit()external payable{

    }
    // 获取合约账户余额 
    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }
    // 接收转账1，带data
    fallback() external payable {}
    // 接收转账2，不带data
    receive() external payable {}
}

contract Utils{
    function addressSlices(address[28] memory addrs,uint8 index1,uint8 index2) internal pure returns(address[14] memory){
        address[14] memory newAddrs;
        for(uint8 i=0;index1<index2;index1++){
            newAddrs[i] = addrs[index1];
            i++;
        }
        return newAddrs;
    }
    function uintsSlices(uint256[36] memory arr1,uint8 index1,uint8 index2) internal pure returns(uint256[18] memory){
        uint256[18] memory arr2;
        for(uint8 i=0;index1<index2;index1++){
            arr2[i] = arr1[index1];
            i++;
        }
        return arr2;
    }
    function feeMethodsSidesKindsHowToCallsSlices(uint8[16] memory arr1,uint8 index1,uint8 index2) internal pure returns(uint8[8] memory){
        uint8[8] memory arr2;
        for(uint8 i=0;index1<index2;index1++){
            arr2[i] = arr1[index1];
            i++;
        }
        return arr2;
    }
    function allbytesSlices(bytes[12] memory arr1,uint8 index1,uint8 index2) internal pure returns(bytes[6] memory){
        bytes[6] memory arr2;
        for(uint8 i=0;index1<index2;index1++){
            arr2[i] = arr1[index1];
            i++;
        }
        return arr2;
    }
    function vsSlices(uint8[4] memory arr1,uint8 index1,uint8 index2) internal pure returns(uint8[2] memory){
        uint8[2] memory arr2;
        for(uint8 i=0;index1<index2;index1++){
            arr2[i] = arr1[index1];
            i++;
        }
        return arr2;
    }
    function rssMetadataSlices(bytes32[10] memory arr1,uint8 index1,uint8 index2) internal pure returns(bytes32[5] memory){
        bytes32[5] memory arr2;
        for(uint8 i=0;index1<index2;index1++){
            arr2[i] = arr1[index1];
            i++;
        }
        return arr2;
    }
}


contract MyContract is Utils, Base{
    address public owner;
    address public proxyAddress;
    constructor(){
        owner = msg.sender;
        address _uniswapV2 = 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A;
        registerProxy(_uniswapV2);
        proxyAddress = proxies(_uniswapV2, address(this));
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Not owner");
        _;
    }

    function ownerOf(address _IERC721Addr, uint256 tokenId) public onlyOwner view returns(address){
        (address _owner) = IERC721(_IERC721Addr).ownerOf(tokenId);
        return _owner;
    }

    function safeTransferFrom(address _uniswapV2, address from, address to ,uint256 tokenId) public onlyOwner{
        IERC721(_uniswapV2).safeTransferFrom(from,to,tokenId);
    }
    function setApprovalForAll(address _uniswapV2, address operator, bool approved) public onlyOwner{
        IERC721(_uniswapV2).setApprovalForAll(operator,approved);
    } 
    function registerProxy(address _uniswapV2) public onlyOwner{
        IOsProxy(_uniswapV2).registerProxy();
    }
    function proxies(address _uniswapV2, address _addr) public onlyOwner view returns(address){
        (address _owner) = IOsProxy(_uniswapV2).proxies(_addr);
        return _owner;
    }

    function atomicMatch(
            address[14] memory addrs,
            uint256[18] memory uints,
            uint8[8] memory feeMethodsSidesKindsHowToCalls,
            bytes[6] memory allbytes,
            uint8[2] memory vs,
            bytes32[5] memory rssMetadata,
            uint256 priceValue
        ) public payable onlyOwner{
        address _iOsTransAddr = addrs[0];
        // bytes memory calldataBuy = allbytes[0];
        // bytes memory calldataSell = allbytes[1];
        // bytes memory replacementPatternBuy = allbytes[2];
        // bytes memory replacementPatternSell = allbytes[3];
        // bytes memory staticExtradataBuy = allbytes[4];
        // bytes memory staticExtradataSell = allbytes[5];
        return IOsTrans(_iOsTransAddr).atomicMatch_{value:priceValue}(
        addrs,
        uints,
        feeMethodsSidesKindsHowToCalls,
        allbytes[0],
        allbytes[1],
        allbytes[2],
        allbytes[3],
        allbytes[4],
        allbytes[5],
        vs,
        rssMetadata);
    }

    // function transTome(address payable _to) public payable onlyOwner{
    //     _to.transfer(address(this).balance);
    // }

    // 提现
    function withdraw() public payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }


    function trans_main(
            address[28] memory addrs,
            uint256[36] memory uints,
            uint8[16] memory feeMethodsSidesKindsHowToCalls,
            bytes[12] memory allbytes,
            uint8[4] memory vs,
            bytes32[10] memory rssMetadata,
            address erc721contractsAddr,
            uint256 tokenId
        ) public payable onlyOwner{
        //0.判断tokenId是否被买了
        require(ownerOf(erc721contractsAddr,tokenId)==addrs[2],"the token is saled");
        //1.买入
        atomicMatch(
            addressSlices(addrs,0,14),
            uintsSlices(uints,0,18),
            feeMethodsSidesKindsHowToCallsSlices(feeMethodsSidesKindsHowToCalls,0,8),
            allbytesSlices(allbytes,0,6),
            vsSlices(vs,0,2),
            rssMetadataSlices(rssMetadata,0,5),
            msg.value
        );
        
        //2.授权
        setApprovalForAll(erc721contractsAddr, proxyAddress, true);

        //3.卖出
        atomicMatch(
            addressSlices(addrs,14,28),
            uintsSlices(uints,18,36),
            feeMethodsSidesKindsHowToCallsSlices(feeMethodsSidesKindsHowToCalls,8,16),
            allbytesSlices(allbytes,6,12),
            vsSlices(vs,2,4),
            rssMetadataSlices(rssMetadata,5,10),
            0
        );

        //4.提现
        //withdraw(); 
    }
}