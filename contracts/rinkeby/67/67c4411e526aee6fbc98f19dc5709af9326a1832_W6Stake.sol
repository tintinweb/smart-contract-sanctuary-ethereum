/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT

/**
 * W6 Game Stake Contract  
 * developer @gamer_noob_stream 
 */

pragma solidity ^0.8.0;


//Declaração do codificador experimental ABIEncoderV2 para retornar tipos dinâmicos
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

    constructor() {
        _transferOwnership(_msgSender());
    }

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

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }


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

    uint256 public totalTokensDepositedBUSD;
    uint256 public totalTokensDepositedBNB;
    uint256 public totalTokensInStakeBUSD;
    uint256 public totalTokensInStakeBNB;

    uint256 public quantosStakesBUSDForamFeitos;
    uint256 public quantosStakesBNBForamFeitos;
    uint256 public totalStakersOn;
    uint256 public quantosStakesForamFeitos;

    uint256 public claim24hrs;
    uint256 public APR;
    uint256 public newBlockTime10dias;

    uint256 public totalEarnBUSDcontract;
    uint256 public totalBUSDconvertedToBNB;
    uint256 public totalBUSDpayStaker;
    uint256 public diferenceBUSDreceived;
    uint256 public balanceBUSDafterPay;

    address public   contratoW6 = 0xa91FF2949ae3ff98336341EdAc72F22950F74459;
    address internal BUSDaddress = 0xDE930B6051c413A7679d03ac339d45b9C7797Dc3;
    address internal UNISWAP_V2_ROUTER  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal WBNBaddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    struct StakeInfoBUSD {        
        uint256 startStake1;
        uint256 startStake2;
        uint256 startStake3;
        uint256 amountTokens1;
        uint256 amountTokens2;
        uint256 amountTokens3;
    }
    struct ClaimInfoBUSD {        
        bool invested1;
        bool invested2;
        bool invested3;
        uint256 amountBUSDClaimed1;
        uint256 amountBUSDClaimed2;
        uint256 amountBUSDClaimed3;
        uint256 totalAmountClaimedBUSD;
    }
    struct StakeInfoBNB {        
        uint256 startStake1;
        uint256 startStake2;
        uint256 startStake3;
        uint256 amountTokens1;
        uint256 amountTokens2;
        uint256 amountTokens3;
    }
    struct ClaimInfoBNB {        
        bool invested1;
        bool invested2;
        bool invested3;
        uint256 amountBNBClaimed1;
        uint256 amountBNBClaimed2;
        uint256 amountBNBClaimed3;
        uint256 totalAmountClaimedBNB;
    }
/**
    struct isBUSDStaker {        
        bool isStakerAddress1;
        bool isStakerAddress2;
        bool isStakerAddress3;
    }

    struct isBNBStaker {        
        bool isStakerAddress1;
        bool isStakerAddress2;
        bool isStakerAddress3;
    }
*/

    event ApostouStaked(address indexed addressStaker, uint256 amountTokens, uint256 whatsStake, uint256 numeroDaAposta);
    event Retirado(address indexed addressStaker, uint256 amountTokens, uint256 amountClaimed, uint256 totalRewardClaimed, uint256 whatsStake, uint256 numeroDaAposta);

    mapping(address => StakeInfoBUSD) public mappingStakeInfoBUSD;
    mapping(address => StakeInfoBNB) public mappingStakeInfoBNB;
    mapping(address => ClaimInfoBUSD) public mappingClaimInfoBUSD;
    mapping(address => ClaimInfoBNB) public mappingClaimInfoBNB;
    //mapping(address => isBUSDStaker) public isBUSDStakerAddrees;
    //mapping(address => isBNBStaker) public isBNBStakerAddrees;

    receive() external payable { }

    constructor() {
        totalEarnBUSDcontract = 0;
        totalBUSDconvertedToBNB = 0;
        totalTokensDepositedBUSD = 0;
        totalTokensDepositedBNB = 0;
        totalTokensInStakeBUSD = 0;
        totalTokensInStakeBNB = 0;
        totalStakersOn = 0;
        quantosStakesForamFeitos = 0;
        quantosStakesBUSDForamFeitos = 0;
        quantosStakesBNBForamFeitos = 0;
        claim24hrs = 60; //86400;
        newBlockTime10dias = 864000;

        totalEarnBUSDcontract = 0;
        totalBUSDconvertedToBNB = 0;
        totalBUSDpayStaker = 0;
        diferenceBUSDreceived = 0;
        totalBUSDconvertedToBNB = 0;
        //balanceBUSDbeforePay = 0;
        balanceBUSDafterPay = 0;

    }    

    function getMappingStakeInfoBNB(address staker) external view returns (StakeInfoBNB memory) {
        return mappingStakeInfoBNB[staker];
    }
    
    function getMappingStakeInfoBUSD(address staker) external view returns (StakeInfoBUSD memory) {
        return mappingStakeInfoBUSD[staker];
    }

    function getPrazoParaExpirarStake(uint256 whatsStake, uint256 whatsNumberStake) external view returns (uint256) {
        uint256 getPrazoParaExpirarStakeReturn;
        uint256 startStake;

        if (whatsStake == 1) {
                if (whatsNumberStake == 1) {
                    startStake = mappingStakeInfoBUSD[_msgSender()].startStake1;
                } else if (whatsNumberStake == 2) {
                    startStake = mappingStakeInfoBUSD[_msgSender()].startStake2;
                } else if (whatsNumberStake == 3) {
                    startStake = mappingStakeInfoBUSD[_msgSender()].startStake3;
                }
        } else if (whatsStake == 2) {
                if (whatsNumberStake == 1) {
                    startStake = mappingStakeInfoBNB[_msgSender()].startStake1;
                } else if (whatsNumberStake == 2) {
                    startStake = mappingStakeInfoBNB[_msgSender()].startStake2;
                } else if (whatsNumberStake == 3) {
                    startStake = mappingStakeInfoBNB[_msgSender()].startStake3;
                }
        }
        
        if (startStake > 0) {
           if (block.timestamp - startStake > 0) {
                return getPrazoParaExpirarStakeReturn = startStake + tempo20diasMinimo - block.timestamp;
            } else {
               return getPrazoParaExpirarStakeReturn = 0;
            }
        } else {
            return getPrazoParaExpirarStakeReturn = 0;
        }
    }
    
    function getMyTokensW6Depositados() external view returns (uint256) {
        return (mappingStakeInfoBUSD[_msgSender()].amountTokens1 + mappingStakeInfoBUSD[_msgSender()].amountTokens1 +
                mappingStakeInfoBUSD[_msgSender()].amountTokens2 + mappingStakeInfoBUSD[_msgSender()].amountTokens2 +
                mappingStakeInfoBUSD[_msgSender()].amountTokens3 + mappingStakeInfoBUSD[_msgSender()].amountTokens3);
    }

    function getBUSDwasClaimed() external view returns (uint256) {
        return (mappingClaimInfoBUSD[_msgSender()].amountBUSDClaimed1 +
                mappingClaimInfoBUSD[_msgSender()].amountBUSDClaimed2 + 
                mappingClaimInfoBUSD[_msgSender()].amountBUSDClaimed3);
    }

    function getBNBwasClaimed() external view returns (uint256) {
        return (mappingClaimInfoBNB[_msgSender()].amountBNBClaimed1 +
                mappingClaimInfoBNB[_msgSender()].amountBNBClaimed2 + 
                mappingClaimInfoBNB[_msgSender()].amountBNBClaimed3);
    }

    function getCalculateGanhosBUSD(address staker, uint256 whatsNumberStake) public view returns (uint256 ganhosBUSD){
        uint256 amountTokens;
        uint256 startStake;
        uint256 totalTokensInStake = totalTokensInStakeBUSD;
            
            if (whatsNumberStake == 1) {
                amountTokens = mappingStakeInfoBUSD[staker].amountTokens1;
                startStake = mappingStakeInfoBUSD[staker].startStake1;
            } else if (whatsNumberStake == 2) {
                amountTokens = mappingStakeInfoBUSD[staker].amountTokens2;
                startStake = mappingStakeInfoBUSD[staker].startStake2;
            } else if (whatsNumberStake == 3) {
                amountTokens = mappingStakeInfoBUSD[staker].amountTokens3;
                startStake = mappingStakeInfoBUSD[staker].startStake3;
            }

        uint256 percentTokens = (amountTokens.mul(10**6)).div(totalTokensInStake);
        uint256 timeIncreaseFactorReturn = timeIncreaseFactor(startStake);
        uint256 amountIncreaseFactorCalc = amountIncreaseFactor(amountTokens);
        
        //essa variável retorna APENAS saldo de BUSD diponível o para pagamentos
        uint256 BUSDbalance = getUpdateBUSDbalanceBeforePay();

        //divisão por 10^30 necessária 
        //percentTokens retorna 10^14 maior
        //timeIncreaseFactor retorna um valor 10^8 maior
        //amountIncreaseFactor retorna um fator 10^8 maior
        ganhosBUSD = BUSDbalance.mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10**22);

        if (ganhosBUSD >= BUSDbalance) {
            ganhosBUSD = BUSDbalance;
        }

        return ganhosBUSD;
    }

    function returnPercentTokens(uint256 amountTokens, uint256 totalTokensStaked) public pure returns  (uint256) {
        uint256 percentTokens = (amountTokens.mul(10**14)).div(totalTokensStaked);
        return percentTokens;
    }

    function getCalculateGanhosBNB(address staker, uint256 whatsNumberStake) public view returns (uint256 ganhosBNB){
        uint256 amountTokens;
        uint256 startStake;
        uint256 totalTokensInStake = totalTokensInStakeBNB;
            
        if (whatsNumberStake == 1) {
            amountTokens = mappingStakeInfoBNB[staker].amountTokens1;
            startStake = mappingStakeInfoBNB[staker].startStake1;
        } else if (whatsNumberStake == 2) {
            amountTokens = mappingStakeInfoBNB[staker].amountTokens2;
            startStake = mappingStakeInfoBNB[staker].startStake2;
        } else if (whatsNumberStake == 3) {
            amountTokens = mappingStakeInfoBNB[staker].amountTokens3;
            startStake = mappingStakeInfoBNB[staker].startStake3;
        }

        uint256 percentTokens = (amountTokens.mul(10**6)).div(totalTokensInStake);
        uint256 timeIncreaseFactorReturn = timeIncreaseFactor(startStake);
        uint256 amountIncreaseFactorCalc = amountIncreaseFactor(amountTokens);
        
        //essa variável retorna APENAS saldo de BNB diponível o para pagamentos
        //e isso inclui os as posteriores conversões de BUSD para BNB
        uint256 BNBaConverter = getUpdateBNBbalanceBeforePay();

        //divisão por 10^30 necessária 
        //percentTokens retorna 10^14 maior
        //timeIncreaseFactor retorna um valor 10^8 maior
        //amountIncreaseFactor retorna um fator 10^8 maior
        ganhosBNB = BNBaConverter.mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10**22);
    
        if (ganhosBNB >= BNBaConverter) {
            ganhosBNB = BNBaConverter;
        }

        return ganhosBNB;
    }

    function totalTokensStakedBNBReturn() public view returns (uint256){
        return totalTokensInStakeBNB;
    }

    function amountIncreaseFactor(uint256 amount) public pure returns (uint256) {
        uint256 factor;
        if (amount <= 5000 * 10 ** 9){
            factor = 100000000;
            return factor;
        } else if (amount > 5000 * 10 ** 9 && amount < 20000 * 10 ** 9){
            factor = 104000000;
            return factor;
        } else if (amount >= 20000 * 10 ** 9 && amount < 70000 * 10 ** 9) {
            factor = 111000000;
            return factor;
        } else if (amount >= 70000 * 10 ** 9 && amount < 150000 * 10 ** 9) {
            factor = 125000000;
            return factor;
        } else if (amount >= 150000 * 10 ** 9) {
            factor = 150000000;
            return factor;
        }
        return factor;
    }

    function returnTimeOfIncreaseFactor(uint256 startStake) public view returns (uint256) {
        uint256 time;

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

    function timeIncreaseFactor(uint256 startStake) public view returns (uint256) {
        uint256 timePassed;
        uint256 timeIncreaseFactorReturn;

        if (block.timestamp <= startStake + tempo20diasMinimo){
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(10**6).mul(30);
                        timeIncreaseFactorReturn = timePassed.div(tempo20diasMinimo);
        } else if (//block.timestamp > startStake + tempo20diasMinimo && 
        block.timestamp < startStake + tempo30dias) {
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(10**6).mul(45);
                        timeIncreaseFactorReturn = timePassed.div(tempo30dias);

        } else if (//block.timestamp > startStake + tempo30dias && 
        block.timestamp < startStake + tempo45dias) {
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(10**6).mul(60);
                        timeIncreaseFactorReturn = timePassed.div(tempo45dias);

        } else if (//block.timestamp > startStake + tempo45dias && 
        block.timestamp < startStake + tempo60dias) {
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(10**6).mul(75);
                        timeIncreaseFactorReturn = timePassed.div(tempo60dias);

        } else if (//block.timestamp > startStake + tempo60dias && 
        block.timestamp < startStake + tempo90dias) {
                        timePassed = block.timestamp - startStake;
                        timePassed = timePassed.mul(10**6).mul(85);
                        timeIncreaseFactorReturn = timePassed.div(tempo90dias);

        } else if (//block.timestamp > startStake + tempo60dias && 
        block.timestamp >= startStake + tempo90dias) {
                        timeIncreaseFactorReturn = 10**8;

        } 
        return timeIncreaseFactorReturn;
    }

    function queryBalanceOf(address tokenAddress) view public returns (uint) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    //calcula o saldo de BUSD disponível para pagamento
    function getUpdateBUSDbalanceBeforePay () public view returns (uint256) {
        uint256 addressThisBalanceOfBUSDReturn;

        addressThisBalanceOfBUSDReturn = 
        (queryBalanceOf(BUSDaddress) - balanceBUSDafterPay).div(2);

        return queryBalanceOf(BUSDaddress) - addressThisBalanceOfBUSDReturn;
    }

    //calcula o saldo de BNB disponível para pagamentos
    function getUpdateBNBbalanceBeforePay () public view returns (uint256) {
        uint256 addressThisBalanceReturn;

        uint256 diferenceBUSDreceivedTemp = queryBalanceOf(BUSDaddress) - balanceBUSDafterPay;
        if (diferenceBUSDreceivedTemp != 0) {
            addressThisBalanceReturn = getUpdateBalanceBUSDtoBNB(diferenceBUSDreceivedTemp.div(2));
        }
        
        return address(this).balance + addressThisBalanceReturn;
        }

    //atualiza o saldo de BNB no contrato para pagamento
    //deixa os saldos de BNB e BUSD atualizados antes de qualquer cálculo ou saída de BNB ou BUSD
    function updateInfoBUSDbeforePay () public {

        //duas condições sempre são verdadeiras
        //contrato sempre recebe BUSD, seja ele ZERO ou maior que ZERO
        /*
        diferenceBUSDreceived sempre é maior que zero,
        motivo pelo qual um bug ou erro lógico nunca é esperado
        **/
        diferenceBUSDreceived = queryBalanceOf(BUSDaddress) - balanceBUSDafterPay;
        if (diferenceBUSDreceived != 0) {
            updateBalanceBUSDtoBNB(diferenceBUSDreceived.div(2));
        }
        totalBUSDconvertedToBNB = totalBUSDconvertedToBNB + diferenceBUSDreceived.div(2);
        //balanceBUSDbeforePay = queryBalanceOf(BUSDaddress);
        totalEarnBUSDcontract += diferenceBUSDreceived;
    }

    //Atualiza infos dos BUSD recebido. Funçao executada APÓS QUAISQUER saídas de BUSD
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

   /**
   function calcAPRbusd () public {
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
        require(mappingClaimInfoBUSD[_msgSender()].invested3 == false, "Limite de 3 stakes atingido");

        uint256 numeroDaAposta;
        
        IERC20(contratoW6).transferFrom(_msgSender(), address(this), stakeAmount);

        if (mappingClaimInfoBUSD[msg.sender].invested1 == false) {
            mappingClaimInfoBUSD[_msgSender()].invested1 = true;
            mappingStakeInfoBUSD[_msgSender()].startStake1 = block.timestamp;
            mappingStakeInfoBUSD[_msgSender()].amountTokens1 = stakeAmount;
            numeroDaAposta = 1;

        } else if (mappingClaimInfoBUSD[msg.sender].invested2 == false) {
            mappingClaimInfoBUSD[_msgSender()].invested2 = true;
            mappingStakeInfoBUSD[_msgSender()].startStake2 = block.timestamp;
            mappingStakeInfoBUSD[_msgSender()].amountTokens2 = stakeAmount;
            numeroDaAposta = 2;

        } else if (mappingClaimInfoBUSD[msg.sender].invested3 == false) {
            mappingClaimInfoBUSD[_msgSender()].invested3 = true;
            mappingStakeInfoBUSD[_msgSender()].startStake3 = block.timestamp;
            mappingStakeInfoBUSD[_msgSender()].amountTokens3 = stakeAmount;
            numeroDaAposta = 3;
        }

        quantosStakesForamFeitos++;
        quantosStakesBUSDForamFeitos++;
        totalStakersOn++;
        totalTokensDepositedBUSD += stakeAmount;
        totalTokensInStakeBUSD += stakeAmount;
        //totalTokensStakedBUSD = totalTokensStakedB + stakeAmount;

        updateInfoBUSDbeforePay();
        updateInfoBUSDafterPay(0);

        emit ApostouStaked(_msgSender(), stakeAmount, 1, numeroDaAposta);
    }    

    function StakeBNBW6(uint256 stakeAmount) external whenNotPaused {
        require(stakeAmount > 0, "Por favor, aposte um valor de tokens maior que ZERO");
        require(IERC20(contratoW6).balanceOf(_msgSender()) >= stakeAmount, "Voce nao possui tokens suficientes");
        require(mappingClaimInfoBNB[_msgSender()].invested3 == false, "Limite de 3 stakes atingido");

        uint256 numeroDaAposta;
        
        IERC20(contratoW6).transferFrom(_msgSender(), address(this), stakeAmount);

        if (mappingClaimInfoBNB[msg.sender].invested1 == false) {
            mappingClaimInfoBNB[_msgSender()].invested1 = true;
            mappingStakeInfoBNB[_msgSender()].startStake1 = block.timestamp;
            mappingStakeInfoBNB[_msgSender()].amountTokens1 = stakeAmount;
            numeroDaAposta = 1;

        } else if (mappingClaimInfoBNB[msg.sender].invested2 == false) {
            mappingClaimInfoBNB[_msgSender()].invested2 = true;
            mappingStakeInfoBNB[_msgSender()].startStake2 = block.timestamp;
            mappingStakeInfoBNB[_msgSender()].amountTokens2 = stakeAmount;
            numeroDaAposta = 2;

        } else if (mappingClaimInfoBNB[msg.sender].invested3 == false) {
            mappingClaimInfoBNB[_msgSender()].invested3 = true;
            mappingStakeInfoBNB[_msgSender()].startStake3 = block.timestamp;
            mappingStakeInfoBNB[_msgSender()].amountTokens3 = stakeAmount;
            numeroDaAposta = 3;
        }
        quantosStakesForamFeitos++;
        quantosStakesBNBForamFeitos++;
        totalStakersOn++;
        totalTokensDepositedBNB += stakeAmount;
        totalTokensInStakeBNB += stakeAmount;
        //totalTokensStakedBNB = totalTokensStakedBNB + stakeAmount;

        updateInfoBUSDbeforePay();
        updateInfoBUSDafterPay(0);

        emit ApostouStaked(_msgSender(), stakeAmount, 2, numeroDaAposta);
    }  

    function claimBUSDandTokensW6(uint256 whatsNumberStake) external {
        require(mappingStakeInfoBUSD[_msgSender()].amountTokens1 > 0 ||
                mappingStakeInfoBUSD[_msgSender()].amountTokens2 > 0 ||
                mappingStakeInfoBUSD[_msgSender()].amountTokens3 > 0, "Sem saldo para retirar");
        //require(mappingStakeInfoBNB[_msgSender()].star + tempo20diasMinimo < block.timestamp, "Tokens bloqueados por 20 dias");
        //require(mappingStakedInfos[_msgSender()].startStakeBNB + tempo20diasMinimo >= block.timestamp
         //      || mappingStakedInfos[_msgSender()].startStakeBUSD + tempo20diasMinimo + newBlockTime10dias 
         //      >= block.timestamp, "Prazo de bloqueios dos tokens ainda nao finalizou");
        
        //totalTokensStakedBNB -= mappingStakedInfos[_msgSender()].amountTokensBNBstake;

        uint256 amountTokens;
        uint256 numeroDaAposta;
        uint256 startStake;
        uint256 totalTokensInStake = totalTokensInStakeBUSD;

        if (whatsNumberStake == 1) {
            require(mappingStakeInfoBUSD[_msgSender()].amountTokens1 > 0, "Voce nao tem apostas e ganhos para retirar");
            startStake = mappingStakeInfoBUSD[_msgSender()].startStake1;
            amountTokens = mappingStakeInfoBUSD[_msgSender()].amountTokens1;
            mappingStakeInfoBUSD[_msgSender()].amountTokens1 = 0;
            numeroDaAposta = 1;

        } else if (whatsNumberStake == 2) {
            require(mappingStakeInfoBUSD[_msgSender()].amountTokens2 > 0, "Voce nao tem apostas e ganhos para retirar");
            startStake = mappingStakeInfoBUSD[_msgSender()].startStake2;
            amountTokens = mappingStakeInfoBUSD[_msgSender()].amountTokens2;
            mappingStakeInfoBUSD[_msgSender()].amountTokens2 = 0;
            numeroDaAposta = 2;

        } else if (whatsNumberStake == 3) {
            require(mappingStakeInfoBUSD[_msgSender()].amountTokens3 > 0, "Voce nao tem apostas e ganhos para retirar");
            startStake = mappingStakeInfoBUSD[_msgSender()].startStake3;
            amountTokens = mappingStakeInfoBUSD[_msgSender()].amountTokens3;
            mappingStakeInfoBUSD[_msgSender()].amountTokens3 = 0;
            numeroDaAposta = 3;

        }
            
        //divisão por 10^22 necessária 
        //percentTokens retorna 10^6 maior
        //timeIncreaseFactor retorna um valor 10^8 maior
        //amountIncreaseFactor retorna um fator 10^8 maior
        uint256 percentTokens = (amountTokens.mul(10**6)).div(totalTokensInStake);
        uint256 timeIncreaseFactorReturn = timeIncreaseFactor(startStake);
        uint256 amountIncreaseFactorCalc = amountIncreaseFactor(amountTokens);
        uint256 ganhosBUSD;
        
        //aqui uma proteção contra exploits de reentrada
        IERC20(contratoW6).transfer(_msgSender(), amountTokens);

        updateInfoBUSDbeforePay();
        ganhosBUSD = (IERC20(BUSDaddress).balanceOf(address(this)))
        .mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10**22);
        
            if (ganhosBUSD < IERC20(BUSDaddress).balanceOf(address(this))) {
                IERC20(BUSDaddress).transfer(_msgSender(), ganhosBUSD);
            } else {
                ganhosBUSD = IERC20(BUSDaddress).balanceOf(address(this));
                IERC20(BUSDaddress).transfer(_msgSender(), ganhosBUSD);
            }
        updateInfoBUSDafterPay(ganhosBUSD);
        
            if (whatsNumberStake == 1) {
                mappingClaimInfoBUSD[_msgSender()].amountBUSDClaimed1 = ganhosBUSD;
            } else if (whatsNumberStake == 2) {
                mappingClaimInfoBUSD[_msgSender()].amountBUSDClaimed2 = ganhosBUSD;
            } else if (whatsNumberStake == 3) {
                mappingClaimInfoBUSD[_msgSender()].amountBUSDClaimed3 = ganhosBUSD;
            }

        totalTokensInStakeBUSD -= amountTokens;
        totalStakersOn--;
        mappingClaimInfoBUSD[_msgSender()].totalAmountClaimedBUSD += ganhosBUSD;
        uint256 totalAmountClaimedBUSDemit = mappingClaimInfoBUSD[_msgSender()].totalAmountClaimedBUSD;
        
        emit Retirado(_msgSender(), amountTokens, ganhosBUSD, totalAmountClaimedBUSDemit, 1, numeroDaAposta);
    }
    
    function claimBNBandTokensW6 (uint256 whatsNumberStake) public {
        require(mappingStakeInfoBNB[_msgSender()].amountTokens1 > 0 ||
                mappingStakeInfoBNB[_msgSender()].amountTokens2 > 0 ||
                mappingStakeInfoBNB[_msgSender()].amountTokens3 > 0, "Sem saldo para retirar");
        //require(isBNBStakerAddrees[_msgSender()].isStakerAddress1 == true ||
             //   isBNBStakerAddrees[_msgSender()].isStakerAddress2 == true ||
              //  isBNBStakerAddrees[_msgSender()].isStakerAddress3 == true, "Sem saldo para retirar");
 
        //require(mappingStakeInfoBNB[_msgSender()].star + tempo20diasMinimo < block.timestamp, "Tokens bloqueados por 20 dias");
        //require(mappingStakedInfos[_msgSender()].startStakeBNB + tempo20diasMinimo >= block.timestamp
         //      || mappingStakedInfos[_msgSender()].startStakeBUSD + tempo20diasMinimo + newBlockTime10dias 
         //      >= block.timestamp, "Prazo de bloqueios dos tokens ainda nao finalizou");
        
        //totalTokensStakedBNB -= mappingStakedInfos[_msgSender()].amountTokensBNBstake;

        uint256 amountTokens;
        uint256 numeroDaAposta;
        uint256 startStake;
        uint256 totalTokensInStake = totalTokensInStakeBNB;
            
        if (whatsNumberStake == 1) {
            require(mappingStakeInfoBNB[_msgSender()].amountTokens1 > 0, "Voce nao tem apostas e ganhos para retirar");
            startStake = mappingStakeInfoBNB[_msgSender()].startStake1;
            amountTokens = mappingStakeInfoBNB[_msgSender()].amountTokens1;
            mappingStakeInfoBNB[_msgSender()].amountTokens1 = 0;
            numeroDaAposta = 1;

        } else if (whatsNumberStake == 2) {
            require(mappingStakeInfoBNB[_msgSender()].amountTokens2 > 0, "Voce nao tem apostas e ganhos para retirar");
            startStake = mappingStakeInfoBNB[_msgSender()].startStake2;
            amountTokens = mappingStakeInfoBNB[_msgSender()].amountTokens2;
            mappingStakeInfoBNB[_msgSender()].amountTokens2 = 0;
            numeroDaAposta = 2;

        } else if (whatsNumberStake == 3) {
            require(mappingStakeInfoBNB[_msgSender()].amountTokens3 > 0, "Voce nao tem apostas e ganhos para retirar");
            startStake = mappingStakeInfoBNB[_msgSender()].startStake3;
            amountTokens = mappingStakeInfoBNB[_msgSender()].amountTokens3;
            mappingStakeInfoBNB[_msgSender()].amountTokens3 = 0;
            numeroDaAposta = 3;

        } else {
            require(false, "3 stakes ja clamados. Tentou clamar novamente");
        }

        //divisão por 10^22 necessária 
        //percentTokens retorna 10^6 maior
        //timeIncreaseFactor retorna um valor 10^8 maior
        //amountIncreaseFactor retorna um fator 10^8 maior
        uint256 amountTokensToCalc = amountTokens.mul(10**6);
        uint256 percentTokens = (amountTokensToCalc).div(totalTokensInStake);
        uint256 timeIncreaseFactorReturn = timeIncreaseFactor(startStake);
        uint256 amountIncreaseFactorCalc = amountIncreaseFactor(amountTokens);
        
        //aqui uma proteção contra exploits de reentrada
        //IERC20(contratoW6).transfer(_msgSender(), amountTokens);
        //divisão por 10^10 necessária por que timeIncreaseFactorReturn retorna um valor 10^8 maior e amountIncreaseFactorCalc 10^2 maior
        updateInfoBUSDbeforePay();
        uint256 ganhosBNB = (address(this).balance).mul(percentTokens).mul(timeIncreaseFactorReturn).mul(amountIncreaseFactorCalc).div(10**22);

        address payable addressStaker = payable(_msgSender());
        if (ganhosBNB != 0) {
            if (ganhosBNB < address(this).balance) {
                    addressStaker.transfer(ganhosBNB);
                } else {
                    ganhosBNB = address(this).balance;
                    addressStaker.transfer(ganhosBNB);
            }
        }
        updateInfoBUSDafterPay(0);
        
            if (whatsNumberStake == 1) {
                mappingClaimInfoBNB[_msgSender()].amountBNBClaimed1 = ganhosBNB;
            } else if (whatsNumberStake == 2) {
                mappingClaimInfoBNB[_msgSender()].amountBNBClaimed2 = ganhosBNB;
            } else if (whatsNumberStake == 3) {
                mappingClaimInfoBNB[_msgSender()].amountBNBClaimed3 = ganhosBNB;
            }

        totalTokensInStakeBUSD -= amountTokens;
        totalStakersOn--;
        mappingClaimInfoBNB[_msgSender()].totalAmountClaimedBNB += ganhosBNB;
        uint256 totalAmountClaimedBNBemit = mappingClaimInfoBNB[_msgSender()].totalAmountClaimedBNB;

        emit Retirado(_msgSender(), amountTokens, ganhosBNB, totalAmountClaimedBNBemit, 2, numeroDaAposta);

    }

    function claimBNBandTokensW6222222 (uint256 whatsNumberStake) public {

        updateInfoBUSDbeforePay();
        
        //aqui uma proteção contra exploits de reentrada
        //IERC20(contratoW6).transfer(_msgSender(), 0);
        //divisão por 10^10 necessária por que timeIncreaseFactorReturn retorna um valor 10^8 maior e amountIncreaseFactorCalc 10^2 maior
        uint256 ganhosBNB = (address(this).balance).mul(50).div(100);

        address payable addressStaker = payable(msg.sender);

        if (ganhosBNB < address(this).balance) {
                addressStaker.transfer(ganhosBNB);
            } else {
                ganhosBNB = address(this).balance;
                addressStaker.transfer(ganhosBNB);
        }
        updateInfoBUSDafterPay(0);
        
            if (whatsNumberStake == 1) {
                mappingClaimInfoBNB[_msgSender()].amountBNBClaimed1 = ganhosBNB;
            } else if (whatsNumberStake == 2) {
                mappingClaimInfoBNB[_msgSender()].amountBNBClaimed2 = ganhosBNB;
            } else if (whatsNumberStake == 3) {
                mappingClaimInfoBNB[_msgSender()].amountBNBClaimed3 = ganhosBNB;
            }
        
        //totalStakersOn--;
        mappingClaimInfoBNB[_msgSender()].totalAmountClaimedBNB += ganhosBNB;
        uint256 totalAmountClaimedBNBemit = mappingClaimInfoBNB[_msgSender()].totalAmountClaimedBNB;

        emit Retirado(_msgSender(), 0, ganhosBNB, totalAmountClaimedBNBemit, 2, 2);

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