/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: Frensware
pragma solidity ^0.8.0;

// Interfaces
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

    interface IFactory {
        function getPair(address tokenA, address tokenB) external view returns (address pair);
        function allPairs(uint) external view returns (address pair);
        function allPairsLength() external view returns (uint);
    }

    interface IPair {
        function token0() external view returns (address);
        function token1() external view returns (address);
        function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
        function price0CumulativeLast() external view returns (uint);
        function price1CumulativeLast() external view returns (uint);
        function kLast() external view returns (uint);
        function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    }

    interface IRouter {
        function factory() external pure returns (address);
        function WETH() external pure returns (address);
        function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
        function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
        function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
        function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

        function swapExactTokensForTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts);
        function swapExactETHForTokens(
            uint amountOutMin, 
            address[] calldata path, 
            address to, 
            uint deadline
        ) external payable returns (uint[] memory amounts);
        function swapExactTokensForETH(
            uint amountIn, 
            uint amountOutMin, 
            address[] calldata path, 
            address to, 
            uint deadline
        ) external returns (uint[] memory amounts);
        function swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
        function swapExactETHForTokensSupportingFeeOnTransferTokens(
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external payable;
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
    }

// Implementation
    contract toaster {
        // DATA
            address private _operator;
            address private _DAO;
            address private _specialNeedsElf;

            address[] private toaststs;
            mapping(address => uint256) tIndex;
            mapping(address => bool) someoneMadeBread;
            mapping(address => bool) buttered;
            
            mapping(address => breadDetails) breadData;
                struct breadDetails {
                    uint256 value;
                    address[] Toasters;
                    mapping(address => uint256) depIndex;
                    mapping(address => bool) isToast;
                }

            mapping(address => mapping(address => userDetails)) userData;
                struct userDetails {
                    uint256 myToast;
                    uint256 extraToast;
                }

            mapping(address => bool) moldyBread;
            mapping(address => bool) honey;

            constructor() { 
                _operator = msg.sender; 
                _specialNeedsElf = msg.sender;    
            }

        // View functions
            function getTheBread() public view returns (address[] memory) { return toaststs; }

            function getBreadData(address t) public view returns(bool, uint256, uint256) {
                breadDetails storage bread = breadData[t];
                return(buttered[t], bread.value, bread.Toasters.length);
            }

            function lookAtMeIAmDataNow(address t) public view returns (uint256, uint256) {
                userDetails storage user = userData[msg.sender][t];
                return(user.myToast, user.extraToast);
            }

        // Active functions
            function makeToast(address t, uint256 a) external thisIsToast(t) edible(t) {
                breadDetails storage bread = breadData[t];
                userDetails storage user = userData[msg.sender][t];
                require(IERC20(t).allowance(msg.sender, address(this)) >= a
                && IERC20(t).balanceOf(msg.sender) >= a);
                IERC20(t).transferFrom(msg.sender, address(this), a);
                if(bread.isToast[msg.sender] == false) { _iMadeToast(t, msg.sender); }
                    bread.value += a;
                    user.myToast += a;
            }

            function lessToast(address t, uint256 a) external thisIsToast(t) {
                breadDetails storage bread = breadData[t];
                userDetails storage user = userData[msg.sender][t];
                require(user.myToast >= a);
                if(user.myToast - a == 0) { _myToastIsGone(t, msg.sender); }
                    user.myToast -= a;
                    bread.value -= a;
                IERC20(t).transfer(msg.sender, a);
            }

            function noMoreToast(address t) external thisIsToast(t) {
                breadDetails storage bread = breadData[t];
                userDetails storage user = userData[msg.sender][t];
                uint256 v = user.myToast;
                    user.myToast -= v;
                    bread.value -= v;
                IERC20(t).transfer(msg.sender, v);
                _myToastIsGone(t, msg.sender);
            }

            function disembowelNonbeliever(
                address t0,
                address t1,
                address r0,
                address r1,
                uint256 a
                    ) external thisIsToast(t0) edible(t0) {
                require(moldyBread[t1] == false);
                breadDetails storage bread = breadData[t0];
                require(a <= bread.value);
                uint256 poof = _performBackflip(t0, t1, r0, r1, a);
                uint256 dust = poof / 2;
                _writeOnToaster(t0, dust);
                    bread.value += dust;

                if(honey[t1] == false) { 
                    uint256 gibsUs = poof / 10;
                        _manageFee(t0, gibsUs); 
                    uint256 gibsMe = (poof * 4) / 10;
                        IERC20(t0).transfer(msg.sender, gibsMe);
                } else {
                    uint256 gibsMe = poof / 2;
                    IERC20(t0).transfer(msg.sender, gibsMe);
                }
            }

            function mackDavisCanSuckIt(address[] memory routers, address[] memory tokens, uint256 val) external {
                require(routers.length == tokens.length, "Unassigned token or router");
                require(_selfCheckout(tokens, val) == true);
                breadDetails storage bread = breadData[tokens[0]];
                uint256 sT1O = IERC20(tokens[0]).balanceOf(address(this));
                uint256 reqP = val + (val / 100);
                uint256 newValue;
                for(uint256 r = 0; r <= routers.length - 1; r++) {
                    if(r == 0) {
                        uint256 v = _performFrontflip(tokens[r], tokens[r+1], routers[r], val);
                        newValue = v;
                    } else if (r == routers.length - 1) {
                        uint256 v = _performFrontflip(tokens[r], tokens[0], routers[r], newValue);
                        require(v >= reqP, "Done messed up AyAyRon");
                        newValue = v;
                    } else {
                        uint256 v = _performFrontflip(tokens[r], tokens[r+1], routers[r], newValue);
                        newValue = v;
                    }
                }

                uint256 P = IERC20(tokens[0]).balanceOf(address(this)) - sT1O;
                uint256 dust = P / 2;
                _writeOnToaster(tokens[0], dust);
                    bread.value += dust;
                uint256 gibsUs = P / 10;
                    _manageFee(tokens[0], gibsUs); 
                uint256 gibsMe = (P * 4) / 10;
                    IERC20(tokens[0]).transfer(msg.sender, gibsMe);
            }

        // Executive Functions
            function makeBread(address b) external onlyOperator {
                require(someoneMadeBread[b] == false);
                someoneMadeBread[b] = true;
                buttered[b] = true;
                    tIndex[b] = toaststs.length;
                    toaststs.push(b);
            }

            function toggleButter(address t) external thisIsToast(t) onlyOperator {
                buttered[t] = !buttered[t];
            }

            function toggleMold(address toast) external onlyOperator {
                require(honey[toast] == false);
                moldyBread[toast] = !moldyBread[toast];
            }

            function toggleHoney(address token) external onlyOperator {
                require(moldyBread[token] == false);
                honey[token] = !honey[token];
            }

            function whoIsPeter(address peter) external onlyOperator {
                require(peter != address(0));
                _DAO = peter;
            }

            function transferIronFist(address fisted) external onlyOperator {
                require(fisted != address(0));
                _operator = fisted;
            }

            function bestowMagic(address s) external {
                require(msg.sender == _specialNeedsElf);
                _specialNeedsElf = s;
            }

            function smolPanik(address t) external onlyOperator {
                breadDetails storage bread = breadData[t];
                    for(uint256 u = 0; u <= bread.Toasters.length-1; u++) {
                        userDetails storage user = userData[bread.Toasters[u]][t];
                        address to = bread.Toasters[u];
                        uint256 mato = user.myToast;
                        IERC20(t).transfer(to,mato);
                        bread.value -= mato;
                        user.myToast -= mato;
                        _myToastIsGone(t, to);
                    }
                buttered[t] = false;
            }

            function muchPanik() external onlyOperator {
                for(uint256 t = 0; t <= toaststs.length-1; t++) {
                    address pota = toaststs[t];
                    breadDetails storage bread = breadData[pota];
                        for(uint256 u = 0; u <= bread.Toasters.length-1; u++) {
                            userDetails storage user = userData[bread.Toasters[u]][pota];
                            address to = bread.Toasters[u];
                            uint256 mato = user.myToast;
                            IERC20(pota).transfer(to,mato);
                            bread.value -= mato;
                            user.myToast -= mato;
                            _myToastIsGone(pota,to);
                        }
                    buttered[pota] = false;
                }
            }

        // internal functions
            function _iMadeToast(address t, address u) internal {
                breadDetails storage bread = breadData[t];
                bread.isToast[u] = true;
                bread.depIndex[u] = bread.Toasters.length;
                bread.Toasters.push(u);
            }

            function _myToastIsGone(address t, address u) internal {
                breadDetails storage bread = breadData[t];
                for(uint256 b = bread.depIndex[u]; b <= bread.Toasters.length - 1; b++) {
                    bread.depIndex[bread.Toasters[b+1]] = bread.depIndex[bread.Toasters[b]];
                    bread.Toasters[b] = bread.Toasters[b+1];
                }
                delete bread.depIndex[u];
                bread.Toasters.pop();
            }

            function _performFrontflip(address t0, address t1, address r0, uint256 val) internal returns(uint256){
                uint256 sT1O = IERC20(t1).balanceOf(address(this));
                    IERC20(t0).approve(r0, val);
                    address[] memory flip;
                    flip = new address[](2);
                    flip[0] = t0;
                    flip[1] = t1;

                    IRouter(r0).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        val, 0, flip, address(this), block.timestamp
                    );

                uint256 sT1T = IERC20(t1).balanceOf(address(this)) - sT1O;  
                return sT1T;              
            }

            function _performBackflip(address t0, address t1, address r0, address r1, uint256 val) internal returns(uint256){
                uint256 sT0O = IERC20(t0).balanceOf(address(this));
                uint256 sT1O = IERC20(t1).balanceOf(address(this));
                uint256 minty = sT0O / 100;
                    IERC20(t0).approve(r0, val);
                    address[] memory back;
                    back = new address[](2);
                    back[0] = t0;
                    back[1] = t1;

                    IRouter(r0).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        val, 0, back, address(this), block.timestamp
                    );

                uint256 sT1T = IERC20(t1).balanceOf(address(this)) - sT1O;
                    IERC20(t1).approve(r1, sT1T);
                    address[] memory flip;
                    flip = new address[](2);
                    flip[0] = t1;
                    flip[1] = t0;

                    IRouter(r1).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        sT1T, 0, flip, address(this), block.timestamp
                    );

                uint256 sT0T = IERC20(t0).balanceOf(address(this));
                    require(sT0T >= sT0O + minty);
                uint256 poof = sT0T - sT0O;
                return poof;
            }

            function _selfCheckout(address[] memory t, uint256 v) internal view returns (bool) {
                require(someoneMadeBread[t[0]] == true && buttered[t[0]] == true, "Invalid start token");
                breadDetails storage bread = breadData[t[0]];
                    require(bread.value >= v, "Insufficient yeast");
                uint256 last = t.length - 1;
                require(t[0] == t[last], "Incomplete Loop");
                for(uint256 b = 0; b <= t.length - 1; b++) {
                    require(moldyBread[t[b]] == false, "Blacklisted token present");
                }
                return true;
            }

            function _writeOnToaster(address t, uint256 val) internal {
                breadDetails storage bread = breadData[t];
                for(uint256 a = 0; a <= bread.Toasters.length - 1; a++) {
                    userDetails storage user = userData[bread.Toasters[a]][t];
                    uint256 per = (user.myToast * 100) / bread.value;
                    uint256 uVal = (val * per) / 100;
                        user.myToast += uVal;
                        user.extraToast += uVal;
                }
            }

            function _manageFee(address t, uint256 val) internal {
                if(_specialNeedsElf != address(0)) { IERC20(t).transfer(_specialNeedsElf, val); }
                else { IERC20(t).transfer(_operator, val); }
            }

        // Modifiers
            modifier onlyOperator() { require(msg.sender == _operator) ;_; }
            modifier thisIsToast(address t) { require(someoneMadeBread[t] == true) ;_; }
            modifier edible(address t) { require(buttered[t] == true) ;_; }
            modifier nonZero(address i) { require(i != address(0)) ;_; }
    }