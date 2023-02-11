// contract uniswap basic
// SPDX-License-Identifier: UNLICENSE
// this contract purpose for learning, it doesn't follow on standard of official uniswap contract
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Uniswap_v1 {
    struct rateToken {
        uint256 first;
        uint256 second;
        bool isUniSwap;
    }

    mapping(address => mapping(address => rateToken)) uniswapToken;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function addUniswapToken(
        address _a,
        address _b,
        uint256 _first,
        uint256 _second
    ) public onlyOwner returns (bool) {
        uniswapToken[_a][_b].isUniSwap = true;
        uniswapToken[_a][_b].first = _first;
        uniswapToken[_a][_b].second = _second;
        uniswapToken[_b][_a].isUniSwap = true;
        uniswapToken[_b][_a].first = _second;
        uniswapToken[_b][_a].second = _first;
        return true;
    }

    // When use this function, this contract alrealdy has a corronspend token
    // owner already has send token to this contract
    // user already has approve token to this contract
    // owner send token to this contract (manually)
    // sender approve token to this contract (manually )
    function swapToken(address _a, address _b, uint256 _amountIn) public {
        require(
            uniswapToken[_a][_b].isUniSwap == true,
            "Unvalid couple of token"
        );
        IERC20 poolFirst = IERC20(_a);
        IERC20 poolSecond = IERC20(_b);
        uint256 firstA = uniswapToken[_a][_b].first;
        uint256 secondB = uniswapToken[_a][_b].second;
        address sender = msg.sender;
        uint256 amountExistA = balanceOfPool(_a);
        uint256 amountExistB = balanceOfPool(_b);
        uint256 amountOut = (_amountIn * secondB) / firstA;
        require(amountExistA >= _amountIn, "Don't enough token in pool");
        require(amountExistB >= amountOut, "Don't enough token in pool");
        // sennd input token to this contract
        poolFirst.transferFrom(sender, address(this), _amountIn);
        // send output token to sender
        poolSecond.transfer(sender, amountOut);
    }

    function withDraw(
        address _a,
        uint256 _amountIn
    ) public onlyOwner returns (bool) {
        IERC20 poolToken = IERC20(_a);
        uint256 tokenExist = balanceOfPool(_a);
        require(
            tokenExist >= _amountIn,
            "Don't enough available in this contract"
        );
        poolToken.transfer(owner, _amountIn);
        return true;
    }

    // Return avaiable token in this contract
    function balanceOfPool(address _tokebCheck) public view returns (uint256) {
        IERC20 poolToken = IERC20(_tokebCheck);
        uint256 balanceOfOwnerToken = poolToken.balanceOf(address(this));
        return balanceOfOwnerToken;
    }

    // Change rate between two token
    function changeTokenRate(
        address _a,
        address _b,
        uint256 _first,
        uint256 _second
    ) public onlyOwner returns (bool) {
        require(
            uniswapToken[_a][_b].isUniSwap == true,
            "Unvalid couple of token"
        );
        uniswapToken[_a][_b].first = _first;
        uniswapToken[_a][_b].second = _second;
        uniswapToken[_b][_a].first = _second;
        uniswapToken[_b][_a].second = _first;
        return true;
    }

    // Get number of token that is approved from sender to this contract
    function getApprove(address _a) public view returns (uint256) {
        IERC20 poolTokenA = IERC20(_a);
        uint256 approveToken = poolTokenA.allowance(msg.sender, address(this));
        return approveToken;
    }
}
// address KABA2: 0x7A53196fA07d45c3309C24c14253bd077AdcA45a
// address KABA1: 0x7c5c6B56bC03A3f857894632E921426a9763c6Bc
// address swap : 0x1a06C0353C8dDd2B49d08374c75f811Eb94977C9
// address owner: 0xaEB8ba03fBb14d1cc324764a173B2171ecB460B3