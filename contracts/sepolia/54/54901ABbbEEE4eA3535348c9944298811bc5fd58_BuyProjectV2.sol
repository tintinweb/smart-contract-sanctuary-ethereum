/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT

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

// File: contracts/transferMaster.sol



/*
                                                                                               
___  ___  ___  ______ _   __ _____ ___________ _       ___  _____  _____ 
|  \/  | / _ \ | ___ \ | / /|  ___|_   _| ___ \ |     / _ \/  __ \|  ___|
| .  . |/ /_\ \| |_/ / |/ / | |__   | | | |_/ / |    / /_\ \ /  \/| |__  
| |\/| ||  _  ||    /|    \ |  __|  | | |  __/| |    |  _  | |    |  __| 
| |  | || | | || |\ \| |\  \| |___  | | | |   | |____| | | | \__/\| |___ 
\_|  |_/\_| |_/\_| \_\_| \_/\____/  \_/ \_|   \_____/\_| |_/\____/\____/ 
                                                                         
                                                                           
*/

pragma solidity ^0.8.0;


contract BuyProjectV2 {

    address public _owner;
    IERC20 private tokenAddress;
    address payable public billeteraDestino;

    struct Project{
        address[] whiteList;
    }

    mapping (string => Project) projects;

    event TransferenciaRealizada(address remitente, address destinatario, uint256 cantidad);

    // @dev: Approve this contract on tokenV2 contract allow transfer methods.
    // @params: IERC20 deployed token address
    //          Reciever address

    constructor(IERC20 _tokenAddress, address payable _billeteraDestino) {
        tokenAddress = _tokenAddress;
        billeteraDestino = _billeteraDestino;
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    function transfer(uint256 amount, string memory _projectName) public {

        // Check amount & WL
        require(amount > 0, "Amount must be greater than zero");
        require (!isInWhitelist(_projectName), "This address is already added to this project");

        // Verificar el saldo del remitente
        uint256 saldoRemitente = tokenAddress.balanceOf(msg.sender);
        require(saldoRemitente >= amount, "Insufficient sender balance");

        // Transferir los tokens al destinatario
        tokenAddress.transferFrom(msg.sender,billeteraDestino, amount);

        emit TransferenciaRealizada(msg.sender, billeteraDestino, amount);
        
        // Add to whitelist
        Project storage project = projects[_projectName];
        project.whiteList.push(msg.sender);
    }

    // @dev: Check if msg.sender wallet is whitelisted.
    function isInWhitelist(string memory _projectName) public view returns(bool) {
        Project storage project = projects[_projectName];
        for (uint256 i = 0; i < project.whiteList.length; ++i){
            if (project.whiteList[i] == msg.sender) {
                return true;
            }   
        }
        return false;
    }

    // @dev: This function is called by the Owner to check projects whitelist.
    function isInWhiteListMaster(string memory _projectName, address _address) onlyOwner public view returns (bool) {
      Project storage project = projects[_projectName];
      for (uint i = 0; i < project.whiteList.length; i++) {
        if (project.whiteList[i] == _address) {
          return true;
        }
      }
      return false;
    }

    function removeFromWhitelist(string memory _projectName, address _address) onlyOwner public {
        Project storage project = projects[_projectName];
        for (uint256 i = 0; i < project.whiteList.length; ++i){
            if (project.whiteList[i] == _address){
                // Asignar la billetera al ultimo elemento de la array
                project.whiteList[i] = project.whiteList[project.whiteList.length - 1];
                // Actualizar el índice del último elemento en el map projects
                projects[_projectName].whiteList[i] = project.whiteList[i];
                // elimina el ultimo valor de la array
                project.whiteList.pop();

                return;
            }
        }
        revert("Address not in whiteList");

    }

}