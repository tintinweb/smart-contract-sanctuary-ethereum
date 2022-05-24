/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


interface IDDFERC721Factory {
    function getPair(address token) external view returns (address pair);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function totalSupply() external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IDDFERC721PoolPair is IERC721{
    function mint(address owner, uint256 tokenId) external;
    function burn(address owner, uint256 lpTokenId) external;
    function updateTokenTime(address owner, uint256 lpTokenId) external;
    function tokenInfo(uint256 lpTokenId) external view returns (uint32, uint32, uint32);
}

interface IDDFERC721Router {
    function deposit(address token, uint256 tokenId) external;
    function withdraw(address token, uint256 lpTokenId) external;
    function withdrawAll(address token) external;
    function receiveInterest(address token,uint256 lpTokenId) external;
    function receiveAllInterest(address token) external;
    function findAllDeposit(address token)
        external
		view
        returns (uint256 amount);
    function findInterest(address token, uint256 lpTokenId)
        external
		view
		returns (uint256 amount);
    function findLPTokens(address token, address account) 
        external
        view
		returns (uint256[] memory _lpTokens, string[] memory _URIs, uint256[] memory _amounts, bool[] memory approvals);
    function findTokens(address token, address account)
        external 
        view 
        returns (uint256[] memory tokens, string[] memory tokenURIs, bool[] memory approvals);
}

contract DDFERC721Router is IDDFERC721Router {
    address public factory;
    address public ddfAddress;
    address public ddfSender;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'DDF: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _factory, address _ddfAddress) {
        factory = _factory;
        ddfAddress = _ddfAddress;
        ddfSender = msg.sender;
    }

    function deposit(address token, uint256 tokenId) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");
        require(IERC721(token).ownerOf(tokenId) == msg.sender, "DDFRouter: transfer of token that is not owner");

        IERC721(token).transferFrom(msg.sender,address(this),tokenId);
        IERC721(token).approve(pair,tokenId);
        IDDFERC721PoolPair(pair).mint(msg.sender, tokenId);
    }

    function withdraw(address token, uint256 lpTokenId) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");
        require(IDDFERC721PoolPair(pair).ownerOf(lpTokenId) == msg.sender, "DDFRouter: withdraw  of lpTokenId that is not owner"); 

        (, uint32 startTime, uint32 reward) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 ddfAmount = CalProfitMath.colProfitAmount(startTime,endTime,reward);
        if(ddfAmount > 0 ){
            IERC20(ddfAddress).transferFrom(ddfSender, msg.sender,ddfAmount);
        }

        IDDFERC721PoolPair(pair).burn(msg.sender, lpTokenId);
    }

    function withdrawAll(address token) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");
        require(IDDFERC721PoolPair(pair).isApprovedForAll(msg.sender,address(this)), "DDFRouter: approve caller is not owner nor approved for all"); 

        uint len = IDDFERC721PoolPair(pair).balanceOf(msg.sender);
        if(len > 0){
            uint256 lpTokenId;
            uint256 ddfAmount;
            uint32 endTime = uint32(block.timestamp % 2 ** 32);
            (uint32 blockStartTime, uint32 startTime, uint32 interestRate) = (0,0,0);
            for(uint i=0;i<len;i++){
                lpTokenId = IDDFERC721PoolPair(pair).tokenOfOwnerByIndex(msg.sender, 0); 
                (blockStartTime, startTime, interestRate) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);
                ddfAmount = CalProfitMath.colProfitAmount(startTime,endTime,interestRate);
                if(ddfAmount > 0 ){
                    IERC20(ddfAddress).transferFrom(ddfSender, msg.sender,ddfAmount);
                }
                IDDFERC721PoolPair(pair).burn(msg.sender, lpTokenId);
            }
        }
    }

    function receiveInterest(address token,uint256 lpTokenId) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");
        require(IDDFERC721PoolPair(pair).ownerOf(lpTokenId) == msg.sender, "DDFRouter: retrieve  of token that is not owner"); 

        (, uint32 startTime, uint32 interestRate) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 ddfAmount = CalProfitMath.colProfitAmount(startTime,endTime,interestRate);
        if(ddfAmount > 0 ){
            IERC20(ddfAddress).transferFrom(ddfSender, msg.sender,ddfAmount);
        }
        IDDFERC721PoolPair(pair).updateTokenTime(msg.sender, lpTokenId);
    }

    function receiveAllInterest(address token) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0),"DDFRouter: pair nonexistent");
        require(IDDFERC721PoolPair(pair).isApprovedForAll(msg.sender,address(this)), "DDFRouter: approve caller is not owner nor approved for all"); 

        uint len = IDDFERC721PoolPair(pair).balanceOf(msg.sender);
        if(len > 0){
            uint256 lpTokenId;
            uint256 ddfAmount;
            uint32 endTime = uint32(block.timestamp % 2 ** 32);
            (uint32 startTime, uint32 interestRate) = (0,0);
            for(uint i=0;i<len;i++){
                lpTokenId = IDDFERC721PoolPair(pair).tokenOfOwnerByIndex(msg.sender, i);
                (, startTime, interestRate) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);
                ddfAmount = CalProfitMath.colProfitAmount(startTime,endTime,interestRate);
                if(ddfAmount > 0 ){
                    IERC20(ddfAddress).transferFrom(ddfSender, msg.sender,ddfAmount);
                }
                IDDFERC721PoolPair(pair).updateTokenTime(msg.sender, lpTokenId);
            }
        }
    }

    function findAllDeposit(address token)
        public
		view
        override
        returns (uint256 amount) {
            address pair = IDDFERC721Factory(factory).getPair(token);
            require(pair != address(0), "DDFRouter: pair nonexistent");
            amount = IDDFERC721PoolPair(pair).totalSupply();
    }

    function findInterest(address token, uint256 lpTokenId)
        public
		view
        virtual
        override
		returns (uint256 amount){
            address pair = IDDFERC721Factory(factory).getPair(token);
            require(pair != address(0), "DDFRouter: pair nonexistent");

            (, uint32 startTime, uint32 interestRate) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);

            if(startTime > 0){
                uint32 endTime = uint32(block.timestamp % 2 ** 32);
                amount = CalProfitMath.colProfitAmount(startTime,endTime,interestRate);
            }
    }

    function findLPTokens(address token, address account) 
        public
        view
		virtual
        override
		returns (uint256[] memory _lpTokens, string[] memory _URIs, uint256[] memory _amounts, bool[] memory approvals){
            address pair = IDDFERC721Factory(factory).getPair(token);
            require(pair != address(0), "DDFRouter: pair nonexistent");

            uint256 len = IDDFERC721PoolPair(pair).balanceOf(account);
            if(len > 0){
                _lpTokens = new uint256[](len); 
                _URIs = new string[](len);
                _amounts = new uint256[](len); 
                approvals = new bool[](len);

                uint32 startTime;
                uint32 interestRate;
                uint32 endTime = uint32(block.timestamp % 2 ** 32);
                uint256 _lpTokenId;
                for(uint32 i=0;i<len;i++){
                    _lpTokenId = IDDFERC721PoolPair(pair).tokenOfOwnerByIndex(account, i);
                    (, startTime, interestRate) = IDDFERC721PoolPair(pair).tokenInfo(_lpTokenId); 
                    _lpTokens[i] = _lpTokenId;
                    _URIs[i] = IDDFERC721PoolPair(pair).tokenURI(_lpTokenId);
                    _amounts[i] = CalProfitMath.colProfitAmount(startTime, endTime, interestRate);
                    if(IDDFERC721PoolPair(pair).getApproved(_lpTokenId) == address(this)){
                        approvals[i] = true;
                    }else{
                        approvals[i] = false;
                    }
                }
            }
    }

    function findTokens(address token, address account)
        public 
        view 
        virtual 
        override
        returns (uint256[] memory tokens, string[] memory tokenURIs, bool[] memory approvals) {
            uint256 len = IERC721(token).balanceOf(account);

            if(len >0){
                tokens = new uint256[](len); 
                tokenURIs  = new string[](len);
                approvals = new bool[](len);
                for(uint i=0;i<len;i++){
                    tokens[i] = IERC721(token).tokenOfOwnerByIndex(account, i);
                    tokenURIs[i] = IERC721(token).tokenURI(tokens[i]);
                    if(IERC721(token).getApproved(tokens[i]) == address(this)){
                        approvals[i] = true;
                    }else{
                        approvals[i] = false;
                    }
                }
            }
    }

}

library CalProfitMath {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function calStepProfit(uint256 amount, uint8 p, uint8 d) internal pure returns (uint256 z) {
        z = mul(amount,p);
        z = div(z,d);
    }
    function calProfit(uint256 dayProfit, uint second) internal pure returns (uint256 z) {
        z = mul(dayProfit,second);
        z = div(z,SECONDS_PER_DAY);
    }

    function colProfitAmount(uint32 startime, uint32 endtime,uint32 DAY_PROFIT) internal pure returns (uint256 totalAmount) {
        totalAmount = calProfit(DAY_PROFIT,sub(endtime,startime));
    }
}