/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT

/**
 * W6 Game Stake Contract  
 * developer @gamer_noob_stream 
 */


pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256);    

    function transfer(address to, uint256 amount) external returns (bool);
}


interface WBNBinterface {
    function withdraw(uint256 amount) external returns (uint256);
}


interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to,
        uint deadline
        ) external returns (uint[] memory amounts);

}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external returns (address);
}


library SafeMath {

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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



contract W6Stake is Pausable, Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using Address for address;

    //uint256 tempo20diasMinimo = 1728000;
    //uint256 tempo30dias = 2592000;
    //uint256 tempo45dias = 3888000;
    //uint256 tempo60dias = 5184000;
    //uint256 tempo90dias = 7776000;

    uint256 tempo20diasMinimo = 60;
    uint256 tempo30dias = 120;
    uint256 tempo45dias = 180;
    uint256 tempo60dias = 240;
    uint256 tempo90dias = 300;


    uint256 public totalTokensStakedBUSD;
    uint256 public totalTokensStakedBNB;
    uint256 public claim24hrs;
    uint256 public APR;
    uint256 public newBlockTime10dias;

    uint256 public totalEarnBUSDcontract;
    uint256 public totalBUSDconvertedToBNB;
    uint256 public totalBUSDpayStaker;
    uint256 public diferenceBUSDreceived;
    uint256 public balanceBUSDbeforePay;
    uint256 public balanceBUSDafterPay;

    uint256 public totalStakers;
    uint256 public quantosStakesForamFeitos;

    address public   contratoW6 = 0x548516F48d2060c4a8a31DA6C91cC4C31055C32A;
    address internal BUSDaddress = 0xDE930B6051c413A7679d03ac339d45b9C7797Dc3;
    address internal UNISWAP_V2_ROUTER  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal WBNBaddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    struct StakeInfo {        
        uint256 startStakeBUSD;
        uint256 startStakeBNB;
        uint256 amountTokensBUSDstake;
        uint256 amountTokensBNBstake;
        uint256 amountBUSDclaimed;
        uint256 amountBNBclaimed;
        uint256 totalAmountBUSDclaimed;
        uint256 totalAmountBNBclaimed;
        uint256 numeroDaAposta;
        uint256 numeroDeApostas; 
    }
    
    event ApostouStaked(address indexed from, uint256 numeroDaAposta, uint256 amountTokens, string whatsStake);
    event Retirado(address indexed from, uint256 numeroDaAposta, uint256 amountTokens, uint256 amountBUSDclaimed, uint256 totalAmountBUSDclaimed, string whatsStake);
    
    mapping(address => StakeInfo) public mappingStakedInfos;
    mapping(address => bool) public isStaker;

    receive() external payable { }

    constructor() {
        totalEarnBUSDcontract = 0;
        totalBUSDconvertedToBNB = 0;
        totalTokensStakedBUSD = 0;
        totalTokensStakedBNB = 0;
        totalStakers = 0;
        quantosStakesForamFeitos = 0;
        claim24hrs = 60; //86400;
        newBlockTime10dias = 864000;

        totalEarnBUSDcontract = 0;
        totalBUSDconvertedToBNB = 0;
        totalBUSDpayStaker = 0;
        diferenceBUSDreceived = 0;
        totalBUSDconvertedToBNB = 0;
        balanceBUSDbeforePay = 0;
        balanceBUSDafterPay = 0;

    }    

    function getMappingStakedInfos(address staker) external view returns (StakeInfo memory) {
        return mappingStakedInfos[staker];
    }

    function getPrazoParaExpirarStakeBUSD() external view returns (uint256) {
        uint256 getPrazoParaExpirarStakeBUSDReturn;
        if (mappingStakedInfos[_msgSender()].startStakeBUSD > 0) {
            return mappingStakedInfos[_msgSender()].startStakeBUSD + tempo20diasMinimo - block.timestamp;
        } else {
            return getPrazoParaExpirarStakeBUSDReturn = 0;
        }
    }
    
    function getPrazoParaExpirarStakeBNB() external view returns (uint256) {
        uint256 getPrazoParaExpirarStakeBNBReturn;
        if (mappingStakedInfos[_msgSender()].startStakeBNB > 0) {
            if (block.timestamp - mappingStakedInfos[_msgSender()].startStakeBNB > 0) {
                return getPrazoParaExpirarStakeBNBReturn = mappingStakedInfos[_msgSender()].startStakeBNB + tempo20diasMinimo - block.timestamp;
            } else {
                return getPrazoParaExpirarStakeBNBReturn = 0;
            }
        } else {
            return getPrazoParaExpirarStakeBNBReturn = 0;
        }
    }

    function getTokensW6Depositados() external view returns (uint256) {
        return (mappingStakedInfos[_msgSender()].amountTokensBUSDstake + mappingStakedInfos[_msgSender()].amountTokensBNBstake);
    }

    function getCalculateGanhosBUSD() public view returns (uint256 ganhosBUSD){
        uint256 percentTokens = mappingStakedInfos[_msgSender()].amountTokensBNBstake.div(totalTokensStakedBNB);
        uint256 timeIncreaseFactorReturn = timeIncreaseFactor(msg.sender, 1);
        uint256 amountIncreaseFactorCalc = 
        amountIncreaseFactor(amountIncreaseFactor(mappingStakedInfos[_msgSender()].amountTokensBUSDstake));
        
        uint256 calc = calcUpdateInfoBUSDbeforePay();

        //divisão por 10^10 necessária por que timeIncreaseFactorReturn retorna um valor 10^8 maior e amountIncreaseFactorCalc 10^2 maior
        ganhosBUSD = calc.mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10000000000);

        return ganhosBUSD;
    }

    function getGanhosBUSD() public view returns (uint256 ganhosBUSD){
        uint256 percentTokens = mappingStakedInfos[_msgSender()].amountTokensBNBstake.div(totalTokensStakedBNB);
        uint256 timeIncreaseFactorReturn = timeIncreaseFactor(msg.sender, 1);
        uint256 amountIncreaseFactorCalc = 
        amountIncreaseFactor(mappingStakedInfos[_msgSender()].amountTokensBUSDstake);
        
        uint256 getUpdateInfoBUSDbeforePayReturn = getUpdateInfoBUSDbeforePay();

        //divisão por 10^10 necessária por que timeIncreaseFactorReturn retorna um valor 10^8 maior e amountIncreaseFactorCalc 10^2 maior
        ganhosBUSD = getUpdateInfoBUSDbeforePayReturn.mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10000000000);

        return ganhosBUSD;
    }

    function getCalculateGanhosBNB(address adr) public view returns (uint256 ganhosBNB){
        uint256 BNBaConverter = getUpdateInfoBUSDbeforePay();

        uint256 percentTokens = mappingStakedInfos[adr].amountTokensBNBstake.div(totalTokensStakedBNB);
        uint256 timeIncreaseFactorReturn = timeIncreaseFactor(adr, 2);
        uint256 amountIncreaseFactorCalc = 
        amountIncreaseFactor(mappingStakedInfos[adr].amountTokensBNBstake);
        
        //divisão por 10^10 necessária por que timeIncreaseFactorReturn retorna um valor 10^8 maior e amountIncreaseFactorCalc 10^2 maior
        ganhosBNB = BNBaConverter.mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10000000000);

        return ganhosBNB;
    }



    function getTotalTokensStakedBNB() public view returns (uint256){
        return totalTokensStakedBNB;
        }

    function amountIncreaseFactor(uint256 amount) public pure returns (uint256) {
        uint256 factor;
        if (amount <= 5000 * 10 ** 9){
            factor = 100;
            return factor;
        } else if (amount > 5000 * 10 ** 9 && amount < 20000 * 10 ** 9){
            factor = 104;
            return factor;
        } else if (amount >= 20000 * 10 ** 9 && amount < 70000 * 10 ** 9) {
            factor = 111;
            return factor;
        } else if (amount >= 70000 * 10 ** 9 && amount < 150000 * 10 ** 9) {
            factor = 125;
            return factor;
        } else if (amount >= 150000 * 10 ** 9) {
            factor = 150;
            return factor;
        }
        return factor;
    }


    function returnTimeOfIncreaseFactor(address adr, uint256 whatsStake) public view returns (uint256) {
        uint256 startStake;
        uint256 time;
        if (whatsStake == 1) {
            startStake = mappingStakedInfos[adr].startStakeBUSD;
        } else {
            startStake = mappingStakedInfos[adr].startStakeBNB;
        }

        if (block.timestamp <= startStake + tempo20diasMinimo){
                        time = 1;
        } else if (//block.timestamp > startStake + tempo20diasMinimo && 
        block.timestamp < startStake + tempo30dias) {
                        time = 2;

        } else if (//block.timestamp > startStake + tempo30dias && 
        block.timestamp < startStake + tempo45dias) {
                        time = 3;

        } else if (//block.timestamp > startStake + tempo45dias && 
        block.timestamp < startStake + tempo60dias) {
                        time = 4;

        } else if (//block.timestamp > startStake + tempo60dias && 
        block.timestamp < startStake + tempo90dias) {
                        time = 5;

        } else if (//block.timestamp > startStake + tempo60dias && 
        block.timestamp >= startStake + tempo90dias) {
                        time = 6;

        } 
        return time;
    }

    function timeIncreaseFactor(address adr, uint256 whatsStake) public view returns (uint256) {
        uint256 timePassed;
        uint256 startStake;
        if (whatsStake == 1) {
            startStake = mappingStakedInfos[adr].startStakeBUSD;
        } else {
            startStake = mappingStakedInfos[adr].startStakeBNB;
        }

        uint256 timeIncreaseFactorReturn;

        if (block.timestamp <= startStake + tempo20diasMinimo){
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(1000000).mul(30);
                        timeIncreaseFactorReturn = timePassed.div(tempo20diasMinimo);
        } else if (//block.timestamp > startStake + tempo20diasMinimo && 
        block.timestamp < startStake + tempo30dias) {
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(1000000).mul(45);
                        timeIncreaseFactorReturn = timePassed.div(tempo30dias);

        } else if (//block.timestamp > startStake + tempo30dias && 
        block.timestamp < startStake + tempo45dias) {
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(1000000).mul(60);
                        timeIncreaseFactorReturn = timePassed.div(tempo45dias);

        } else if (//block.timestamp > startStake + tempo45dias && 
        block.timestamp < startStake + tempo60dias) {
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(1000000).mul(75);
                        timeIncreaseFactorReturn = timePassed.div(tempo60dias);

        } else if (//block.timestamp > startStake + tempo60dias && 
        block.timestamp < startStake + tempo90dias) {
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(1000000).mul(85);
                        timeIncreaseFactorReturn = timePassed.div(tempo90dias);

        } else if (//block.timestamp > startStake + tempo60dias && 
        block.timestamp >= startStake + tempo90dias) {
                        timeIncreaseFactorReturn = 100000000;

        } 
        return timeIncreaseFactorReturn;
    }


    function queryBalanceOf(address tokenAddress) view public returns (uint) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    //calcula o saldo de BUSD disponível para pagamento
    function calcUpdateInfoBUSDbeforePay () public view returns (uint256) {
        uint256 addressThisBalanceOfBUSDReturn;

        addressThisBalanceOfBUSDReturn = 
        queryBalanceOf(BUSDaddress) - ((queryBalanceOf(BUSDaddress) - balanceBUSDafterPay).div(2));

        return addressThisBalanceOfBUSDReturn;
    }

    //calcula o saldo de BNB disponível para pagamentos
    function getUpdateInfoBUSDbeforePay () public view returns (uint256) {
        uint256 addressThisBalanceReturn;

        uint256 diferenceBUSDreceivedTemp = queryBalanceOf(BUSDaddress) - balanceBUSDafterPay;
        if (diferenceBUSDreceivedTemp != 0) {
            addressThisBalanceReturn = getUpdateBalanceBUSDtoBNB(diferenceBUSDreceivedTemp.div(2));
        }
        
        return address(this).balance + addressThisBalanceReturn;
        }

    //atualiza o saldo de BNB no contrato para pagamento
    function updateInfoBUSDbeforePay () public {

        //duas condições sempre são verdadeiras
        //contrato sempre recebe BUSD, seja ele ZERO ou maior que ZERO
        /*
        diferenceBUSDreceived sempre é maior que zero,
        motivo pelo qual um bug ou erro lógico nunca é esperado
        **/
        diferenceBUSDreceived = queryBalanceOf(BUSDaddress) - balanceBUSDafterPay;
        totalEarnBUSDcontract += diferenceBUSDreceived;
        if (diferenceBUSDreceived != 0) {
            updateBalanceBUSDtoBNB(diferenceBUSDreceived.div(2));
        }
        totalBUSDconvertedToBNB = totalBUSDconvertedToBNB + diferenceBUSDreceived.div(2);
        balanceBUSDbeforePay = queryBalanceOf(BUSDaddress);

    }

    //Atualiza infos dos BUSD recebido. Funçao executada antes de qualquer saída de BUSD
    function updateInfoBUSDafterPay (uint256 amount) public {
        totalBUSDpayStaker += amount; 
        balanceBUSDafterPay = queryBalanceOf(BUSDaddress);
        }

    //atualiza o saldo de BNB do contrato convertendo desde BUSD
    function updateBalanceBUSDtoBNB (uint256 amount) public {

        IERC20(BUSDaddress).approve(address(UNISWAP_V2_ROUTER), amount);
        // make the swap
        // generate the uniswap pair path of W6 to WBNB/BNB
        address[] memory path = new address[](2);
        path[0] = address(BUSDaddress);
        path[1] = address(WBNBaddress);

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETH(amount, 0, path, address(this), block.timestamp);
    }
    
    //retorna a atualização mais recente para o saldo de BNB do contrato convertendo desde BUSD
    function getUpdateBalanceBUSDtoBNB(uint256 amount) public view returns (uint256) {
        
        uint256 retorno;
        // generate the uniswap pair path of W6 to WBNB/BNB
        address[] memory path = new address[](2);
        path[0] = BUSDaddress;
        path[1] = WBNBaddress;

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
        .getAmountsOut(amount, path);
        return retorno = amountOutMins[path.length -1];
    }  

   /**- function calcAPRbusd () public {
        require()
        uint256 lastAmountTokens24hrs;
        if (IERC20(contratoW6).balanceOf(address(this) - totalTokensStakedBUS > 0) {
            return lastAmountTokens24hrs = IERC20(contratoW6).balanceOf(address(this) - totalTokensStakedBUS;
        } else {
            return lastAmountTokens24hrs = totalTokensStakedBUS - IERC20(contratoW6).balanceOf(address(this);
        }

    }*/

    function StakeBUSDW6(uint256 stakeAmount) external whenNotPaused {
        require(stakeAmount > 0, "Por favor, aposte um valor de tokens maior que ZERO");
        require(IERC20(contratoW6).balanceOf(_msgSender()) >= stakeAmount, "Voce nao possui tokens suficientes");
            
            IERC20(contratoW6).transferFrom(_msgSender(), address(this), stakeAmount);
            quantosStakesForamFeitos++;
            totalStakers++;
            totalTokensStakedBUSD += stakeAmount;
            isStaker[_msgSender()] = true;

            updateInfoBUSDbeforePay();
            updateInfoBUSDafterPay(0);

            uint256 i = 0;
            for(i; i < mappingStakedInfos[_msgSender()].numeroDeApostas + 1; i++) {
                //não faz nada 
                mappingStakedInfos[_msgSender()].numeroDaAposta = i;
            }

            mappingStakedInfos[_msgSender()] = StakeInfo({                
                startStakeBUSD: block.timestamp,
                startStakeBNB: mappingStakedInfos[_msgSender()].startStakeBNB,
                amountTokensBUSDstake: mappingStakedInfos[_msgSender()].amountTokensBUSDstake.add(stakeAmount),
                amountTokensBNBstake: mappingStakedInfos[_msgSender()].amountTokensBNBstake,
                amountBUSDclaimed: mappingStakedInfos[_msgSender()].amountBUSDclaimed,
                amountBNBclaimed: mappingStakedInfos[_msgSender()].amountBNBclaimed,
                totalAmountBUSDclaimed: mappingStakedInfos[_msgSender()].totalAmountBUSDclaimed,
                totalAmountBNBclaimed: mappingStakedInfos[_msgSender()].totalAmountBNBclaimed,
                numeroDaAposta: mappingStakedInfos[_msgSender()].numeroDaAposta,
                numeroDeApostas: mappingStakedInfos[_msgSender()].numeroDeApostas++
            });

        
        emit ApostouStaked(_msgSender(), mappingStakedInfos[_msgSender()].numeroDaAposta, stakeAmount, "BUSD staker");
    }    

    function StakeBNBW6(uint256 stakeAmount) external whenNotPaused {
        require(stakeAmount > 0, "Por favor, aposte um valor de tokens maior que ZERO");
        require(IERC20(contratoW6).balanceOf(_msgSender()) >= stakeAmount, "Voce nao possui tokens suficientes");
        
            IERC20(contratoW6).transferFrom(_msgSender(), address(this), stakeAmount);
            quantosStakesForamFeitos++;
            totalStakers++;
            totalTokensStakedBNB = totalTokensStakedBNB + stakeAmount;
            isStaker[_msgSender()] = true;

            updateInfoBUSDbeforePay();
            updateInfoBUSDafterPay(0);

            uint256 i = 0;
            for(i; i < mappingStakedInfos[_msgSender()].numeroDeApostas + 1; i++) {
                //não faz nada saporra aqui huehue
                mappingStakedInfos[_msgSender()].numeroDaAposta = i;
            }

            mappingStakedInfos[_msgSender()] = StakeInfo({                
                startStakeBUSD: mappingStakedInfos[_msgSender()].startStakeBUSD,
                startStakeBNB: block.timestamp,
                amountTokensBUSDstake: mappingStakedInfos[_msgSender()].amountTokensBUSDstake,
                amountTokensBNBstake: mappingStakedInfos[_msgSender()].amountTokensBNBstake.add(stakeAmount),
                amountBUSDclaimed: mappingStakedInfos[_msgSender()].amountBUSDclaimed,
                amountBNBclaimed: mappingStakedInfos[_msgSender()].amountBNBclaimed,
                totalAmountBUSDclaimed: mappingStakedInfos[_msgSender()].totalAmountBUSDclaimed,
                totalAmountBNBclaimed: mappingStakedInfos[_msgSender()].totalAmountBNBclaimed,
                numeroDaAposta: mappingStakedInfos[_msgSender()].numeroDaAposta,
                numeroDeApostas: mappingStakedInfos[_msgSender()].numeroDeApostas++

            });
        
        emit ApostouStaked(_msgSender(), mappingStakedInfos[_msgSender()].numeroDaAposta, stakeAmount, "BNB Staker");
    }  

    function claimBUSDandTokensW6() external returns (bool){
        require(isStaker[_msgSender()] == true, "Voce ainda nao apostou tokens em stake");
        require(mappingStakedInfos[_msgSender()].startStakeBUSD + claim24hrs <= block.timestamp, "Voce precisa esperar 24hrs para dar o claim");
        //require(mappingStakedInfos[_msgSender()].startStakeBUSD + tempo20diasMinimo >= block.timestamp
        //       || mappingStakedInfos[_msgSender()].startStakeBUSD + tempo20diasMinimo + newBlockTime10dias 
        //       >= block.timestamp, "Prazo de bloqueios dos tokens ainda nao finalizou");

        totalStakers--;
        totalTokensStakedBUSD -= mappingStakedInfos[_msgSender()].amountTokensBUSDstake;
        isStaker[_msgSender()] = false;

        mappingStakedInfos[_msgSender()].amountBUSDclaimed = mappingStakedInfos[_msgSender()].amountBUSDclaimed.
        add(getGanhosBUSD());
        //aqui uma proteção contra exploits de reentrada
        mappingStakedInfos[_msgSender()].amountTokensBUSDstake = mappingStakedInfos[_msgSender()].amountTokensBUSDstake.
        sub(mappingStakedInfos[_msgSender()].amountTokensBUSDstake);
        IERC20(contratoW6).transfer(_msgSender(), mappingStakedInfos[_msgSender()].amountTokensBUSDstake);
        
        updateInfoBUSDbeforePay();
        uint256 stakeBUSDearn = getGanhosBUSD();
        IERC20(BUSDaddress).transfer(_msgSender(), stakeBUSDearn);
        updateInfoBUSDafterPay(stakeBUSDearn);

        mappingStakedInfos[_msgSender()].totalAmountBUSDclaimed = mappingStakedInfos[_msgSender()].totalAmountBUSDclaimed + stakeBUSDearn;

        emit Retirado(_msgSender(), mappingStakedInfos[_msgSender()].amountTokensBUSDstake, mappingStakedInfos[_msgSender()].numeroDaAposta,
        stakeBUSDearn, mappingStakedInfos[_msgSender()].totalAmountBUSDclaimed, "BUSD staker");

        return true;
    }

        function getUpdateBalanceBUSDtoBNB() public view returns (uint256) {
            return mappingStakedInfos[_msgSender()].amountTokensBNBstake;
    }
    

    uint256 public stakeBNBearn;
    uint256 public ganhosBNB2;

    function stakeBNBearnReturn () public view returns (uint256) {
        return stakeBNBearn;
    }

    function claimBNBStakeW6tokens() external {
        require(isStaker[_msgSender()] == true, "Voce ainda nao apostou tokens em stake");
        //require(mappingStakedInfos[_msgSender()].amountTokensBNBstake > 0, "Sem saldo para retirar");
        //require(mappingStakedInfos[_msgSender()].startStakeBNB + tempo20diasMinimo < block.timestamp, "Tokens bloqueados por 20 dias");
        //require(mappingStakedInfos[_msgSender()].startStakeBNB + tempo20diasMinimo >= block.timestamp
         //      || mappingStakedInfos[_msgSender()].startStakeBUSD + tempo20diasMinimo + newBlockTime10dias 
         //      >= block.timestamp, "Prazo de bloqueios dos tokens ainda nao finalizou");

        totalStakers--;
        //totalTokensStakedBNB -= mappingStakedInfos[_msgSender()].amountTokensBNBstake;
        uint256 amountWithdrawals = mappingStakedInfos[_msgSender()].amountTokensBNBstake;
        isStaker[_msgSender()] = false;

        //aqui uma proteção contra exploits de reentrada
        mappingStakedInfos[_msgSender()].amountTokensBNBstake = 0;

        IERC20(contratoW6).transfer(_msgSender(), amountWithdrawals);
        uint256 ganhosBNB;
        uint256 BNBaConverter = getUpdateInfoBUSDbeforePay();

        uint256 percentTokens = mappingStakedInfos[_msgSender()].amountTokensBNBstake.div(totalTokensStakedBNB);
        uint256 timeIncreaseFactorReturn = timeIncreaseFactor(_msgSender(), 2);
        uint256 amountIncreaseFactorCalc = 
        amountIncreaseFactor(mappingStakedInfos[_msgSender()].amountTokensBNBstake);
        
        //divisão por 10^10 necessária por que timeIncreaseFactorReturn retorna um valor 10^8 maior e amountIncreaseFactorCalc 10^2 maior
        
        ganhosBNB = BNBaConverter.mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10000000000);
        ganhosBNB2 = BNBaConverter.mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10000000000);

        stakeBNBearn = ganhosBNB;
        updateInfoBUSDbeforePay();

        mappingStakedInfos[_msgSender()].amountBNBclaimed = mappingStakedInfos[_msgSender()].amountBNBclaimed.
        add(stakeBNBearn);

        mappingStakedInfos[_msgSender()].totalAmountBNBclaimed = mappingStakedInfos[_msgSender()].totalAmountBNBclaimed +stakeBNBearn;
        
        //BNBpay2(payable(msg.sender),stakeBNBearn);

        emit Retirado(_msgSender(), mappingStakedInfos[_msgSender()].amountTokensBNBstake, mappingStakedInfos[_msgSender()].numeroDaAposta,
        stakeBNBearn, mappingStakedInfos[_msgSender()].totalAmountBUSDclaimed, "BNB staker");

    }

    function BNBpay (address payable adr) public {
        uint256 stakeBNBearnTemp = stakeBNBearn;
        if (stakeBNBearnTemp < address(this).balance) {
        adr.transfer(stakeBNBearnTemp);
        } else {
            stakeBNBearnTemp = address(this).balance;
            adr.transfer(stakeBNBearnTemp);
        }
    }
    function BNBpay2 (address payable adr, uint256 amt) public {
        if (amt < address(this).balance) {
        adr.transfer(amt);
        } else {
            amt = address(this).balance;
            adr.transfer(amt);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function managerBNB ()  public onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    //Função que permite ao proprietário/administrador recuperar tokens ERC20 depositados no contrato
    function managerERC20 (address token) public onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}