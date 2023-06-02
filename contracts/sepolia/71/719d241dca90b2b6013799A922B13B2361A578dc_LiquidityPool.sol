/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/ETH_LP.sol



/*
 ______                                           ________         __                           
 /      \                                         /        |       /  |                          
/$$$$$$  | __   __   __   ______    ______        $$$$$$$$/______  $$ |   __   ______   _______  
$$ \__$$/ /  | /  | /  | /      \  /      \          $$ | /      \ $$ |  /  | /      \ /       \ 
$$      \ $$ | $$ | $$ | $$$$$$  |/$$$$$$  |         $$ |/$$$$$$  |$$ |_/$$/ /$$$$$$  |$$$$$$$  |
 $$$$$$  |$$ | $$ | $$ | /    $$ |$$ |  $$ |         $$ |$$ |  $$ |$$   $$<  $$    $$ |$$ |  $$ |
/  \__$$ |$$ \_$$ \_$$ |/$$$$$$$ |$$ |__$$ |         $$ |$$ \__$$ |$$$$$$  \ $$$$$$$$/ $$ |  $$ |
$$    $$/ $$   $$   $$/ $$    $$ |$$    $$/          $$ |$$    $$/ $$ | $$  |$$       |$$ |  $$ |
 $$$$$$/   $$$$$/$$$$/   $$$$$$$/ $$$$$$$/           $$/  $$$$$$/  $$/   $$/  $$$$$$$/ $$/   $$/ 
                                  $$ |                                                           
                                  $$ |                                                           
                                  $$/                                                            
*/

pragma solidity ^0.8.0;


contract LiquidityPool {
    address private owner;
    IERC20 private token;
    uint256 public tokenBalance;
    uint256 public ethBalance;

    constructor(IERC20 _tokenAddress) {
        owner = msg.sender;
        token = _tokenAddress;
        ethBalance = address(this).balance;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    event PoolInitialized(
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 initialPrice
    );
    event SwapETHForTokens(
        address sender,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    event SwapTokensForETH(
        address sender,
        uint256 tokenAmount,
        uint256 ethAmount
    );
    event LiquidityRefilled(uint256 tokenAmount, uint256 ethAmount);
    event ETHWithdrawn(address recipient, uint256 amount);
    event TokenWithdrawn(address recipient, uint256 amount);
    
    
    /**
     * @dev Inicializa la liquidez del pool, depositando tokens y ETH en el contrato. msg.value = ETH unit
     * @param initialTokenAmount Cantidad de tokens a depositar.
     */
    function initializePool(uint256 initialTokenAmount) onlyOwner external payable {
        require(tokenBalance == 0 && ethBalance == 0, "Pool already initialized");

        require(initialTokenAmount > 0, "Token amount must be greater than zero");
        require(msg.value > 0, "ETH amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= initialTokenAmount, "Insufficient tokens");

        // Aprobar la transferencia de tokens desde el usuario al contrato de la pool de liquidez
        token.approve(address(this), initialTokenAmount);

        // Calcular el precio inicial en Gwei
        uint256 initialPrice = (msg.value * 1e9) / initialTokenAmount;

        // Transferir tokens al contrato de la pool de liquidez
        token.transferFrom(msg.sender, address(this), initialTokenAmount);

        // Actualizar los saldos de tokens y ETH en gwei
        tokenBalance = initialTokenAmount;

        //El 1e9 sirve para que el ethBalance este en gwei
        ethBalance = msg.value/1e9;

        // Emitir un evento para indicar que la pool ha sido inicializada
        emit PoolInitialized(initialTokenAmount, msg.value, initialPrice);
    }

    /**
     * @dev Rellena la liquidez del pool en cualquier momento.
     * @param tokenAmount Cantidad de tokens a depositar.

     */
    function refillLiquidity(uint256 tokenAmount) external payable onlyOwner {
        require(tokenAmount > 0, "Token amount must be greater than zero");
        require(msg.value > 0, "ETH amount must be greater than zero");

        // Aprobar la transferencia de tokens desde el usuario al contrato de la pool de liquidez
        token.approve(address(this), tokenAmount);

        // Transferir tokens al contrato de la pool de liquidez
        token.transferFrom(msg.sender, address(this), tokenAmount);

        // Actualizar los saldos de tokens y ETH
        tokenBalance += tokenAmount;
        ethBalance += msg.value/1e9;

        // Emitir un evento para indicar que se ha rellenado la liquidez
        emit LiquidityRefilled(tokenAmount, msg.value);
    }

    /**
     * @dev Permite intercambiar ETH por token.
     */

    function swapETHForTokens() external payable {
        require(msg.value > 0, "ETH amount must be greater than zero");
        require(ethBalance > 0, "No liquidity in the pool");

        // Calcular la cantidad de tokens a transferir en Gwei
        // msg.value = wei --> parseamos a gwei y para calcular el amount dividimos por el precio en gwei
        uint256 tokenAmount = (msg.value / 1e9) / getTokenPrice();

        // Transferir tokens al usuario
        token.transfer(msg.sender, tokenAmount);

        // Actualizar los saldos de tokens y ETH
        tokenBalance -= tokenAmount;
        ethBalance += msg.value/1e9;

        // Emitir un evento para indicar que se ha realizado el intercambio
        emit SwapETHForTokens(msg.sender, msg.value, tokenAmount);
    }

    /**
     * @dev Permite intercambiar tokens por ETH.
     * @param tokenAmount Cantidad de tokens a intercambiar.
     */
    function swapTokensForETH(uint256 tokenAmount) external {
        require(token.balanceOf(msg.sender) >= tokenAmount,"Insufficient tokens");
        require(ethBalance > 0, "No liquidity in the pool");

        // Calcular la cantidad de ETH a transferir en Gwei
        uint256 ethAmount = tokenAmount * getTokenPrice();

        // Transferir tokens al contrato de la pool de liquidez
        token.transferFrom(msg.sender, address(this), tokenAmount);

        // Transferir ETH al usuario
        payable(msg.sender).transfer(ethAmount*1e9);

        // Actualizar los saldos de tokens y ETH
        tokenBalance += tokenAmount;
        ethBalance -= ethAmount;

        // Emitir un evento para indicar que se ha realizado el intercambio
        emit SwapTokensForETH(msg.sender, tokenAmount, ethAmount);
    }

    /**
     * @dev Permite al owner retirar ETH del contrato.
     * @param amount Cantidad de ETH a retirar. --> amount = gwei
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        uint256 amountInGwei = amount * 1e9;  // Convertir el monto a Gwei

        require(ethBalance >= amount, "Insufficient ETH balance");

        // Transferir ETH al propietario
        payable(owner).transfer(amountInGwei);

        // Actualizar el saldo de ETH
        ethBalance -= amount;

        // Emitir un evento para indicar que se ha retirado ETH
        emit ETHWithdrawn(owner, amountInGwei);
    }


    /**
     * @dev Permite al owner retirar tokens del contrato.
     * @param amount Cantidad de tokens a retirar.
     */
    function withdrawToken(uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");

        // Transferir tokens al owner
        token.transfer(msg.sender, amount);

        // Actualizar el saldo de tokens
        tokenBalance -= amount;

        // Emitir un evento para indicar que se ha retirado tokens
        emit TokenWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Obtiene el saldo actual del pool.
     * @return Saldo de tokens y saldo de ETH en Gwei.
     */
    function getPoolBalance() external view returns (uint256, uint256) {
        return (tokenBalance, ethBalance);
    }

    /**
     * @dev Obtiene el precio de la pool (tokens/ETH).
     * @return Precio de la pool en Gwei.
     */
    function getTokenPrice() public view returns (uint256) {
        require(ethBalance > 0 && tokenBalance > 0, "Pool not initialized");

        // Calcular el precio de la pool (tokens/ETH) en Gwei
        uint256 poolPrice = (ethBalance) / tokenBalance;

        return poolPrice;
    }
}