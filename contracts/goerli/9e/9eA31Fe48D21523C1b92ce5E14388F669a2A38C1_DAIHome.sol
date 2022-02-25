/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// File: contracts/wrap.sol


pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
}

interface IERC20Mintable {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    function mint(address mintee, uint amount) external; 
}

interface ZetaMPI {
    function zetaMessageSend(uint16 destChainID, bytes calldata  destContract, uint zetaAmount, uint gasLimit, bytes calldata message, bytes calldata zetaParams) external;
}

interface ZetaMPIReceiver {
	function uponZetaMessage(bytes calldata sender, uint16 srcChainID, address destContract, uint zetaAmount, bytes calldata message) external; 
}


contract DAIHome {
    address public MPI;
    address public DAI_TOKEN; 

    constructor(address _mpi, address _dai_token) {
        MPI = _mpi; 
        DAI_TOKEN = _dai_token;
       
    }

    function wrap(uint16 _destChain, bytes calldata _destContract, uint _amount, address _to) external {
        IERC20(DAI_TOKEN).transferFrom(msg.sender, address(this), _amount); 
        bytes memory message = abi.encode(_amount, _to);
        ZetaMPI(MPI).zetaMessageSend(_destChain, _destContract, 0, 250000, message, message);
    }

	function uponZetaMessage(bytes calldata sender, uint16 srcChainID, address destContract, uint zetaAmount, bytes calldata message) external {
        require(msg.sender == MPI, "permission error"); 
        (uint256 amount, address to) = abi.decode(message, (uint256, address));
        IERC20(DAI_TOKEN).transfer(to, amount); 
    }
}

contract DAIAway {
    address public MPI;
    address public ZDAI_TOKEN; 
    constructor(address _mpi, address _zdai_token) {
        MPI = _mpi; 
        ZDAI_TOKEN = _zdai_token; 
    }
    function unwrap(uint16 _destChain, bytes calldata _destContract, uint _amount, address _to) external {
        IERC20(ZDAI_TOKEN).transferFrom(msg.sender, address(0xdeadbeef), _amount); 
        bytes memory message = abi.encode(_amount, _to);
        // IERC20(ZDAI_TOKEN).burnFrom(msg.sender, _amount); 
        ZetaMPI(MPI).zetaMessageSend(_destChain, _destContract, 0, 250000, message, message);
    }
	function uponZetaMessage(bytes calldata sender, uint16 srcChainID, address destContract, uint zetaAmount, bytes calldata message) external {

        require(msg.sender == MPI, "permission error"); 
        (uint256 amount, address to) = abi.decode(message, (uint256, address));
	// The zDAI ERC20 token contract should list the DAIAway as Minter. 
        IERC20Mintable(ZDAI_TOKEN).mint(to, amount); 
    }
}