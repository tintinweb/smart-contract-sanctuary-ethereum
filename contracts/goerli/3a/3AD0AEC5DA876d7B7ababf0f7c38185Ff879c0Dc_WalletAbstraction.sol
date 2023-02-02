// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

interface IV2SwapRouter {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountIn);
}


interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}


contract WalletAbstraction {
    /*
    My attempt at creating an account abstraction wallet using the
    current Ethereum protocols.
    */
    address payable public admin;
    address immutable public creator;
    address temporaryNewAdmin;
    bool private mutex;
    bytes32 tempOtp1;
	bytes32 otp1;
    bytes32 otp2;
    uint256 initUpdateTimestamp;
    uint256 resetFee;
    constructor(uint256 _resetFee) {
        admin = payable(msg.sender);
        creator = msg.sender;
        mutex = false;
        resetFee = _resetFee;
    }
    event RecoveryInit(address caller, address origin);
    event RecoveryReset(address caller, address origin);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier axx {
        require(msg.sender == admin||msg.sender == creator);
        _;

    }

    modifier noReentrency{
        require(! mutex, "Access Denied");
        mutex = true;
        _;
        mutex = false;
    }

    function swap(address router, address[] memory path, uint256 _amount) external axx {
        /*
        Any modern ETH wallet needs to be able to do swaps!
        */
        IERC20(path[0]).approve(router, _amount);
        uint deadline = block.timestamp + 300;
        IV2SwapRouter(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
    }

    function recoverEth() external axx {
        /*
        Allows the admin to withdraw Ethereum
        */
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverTokens(address tokenAddress) external axx noReentrency {
        /*
        Allows the admin to withdraw ERC20 tokens
        */
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function hash(string memory _string) public pure returns(bytes32) {
        /*
        Sha256 function for emergency admin reset feature
       */
        return keccak256(abi.encodePacked(_string));
        }

    function setOtp(bytes32 s1, bytes32 s2) public axx {
        /*
        Allows administrator to update the hashes
        */
        otp1 = s1;
        otp2 = s2;

    }

    function resetFailedAdminUpdate() public payable noReentrency {
        /*
        If initUpdateAdmin is called, but commit fails,
        this function must be called after a 24 hour delay
        before the process can be attempted again. Requires
        a fee (this is to deter abuse).
        */
        require(initUpdateTimestamp != 0, "Nothing to reset");
        require(block.timestamp > initUpdateTimestamp + 86400, "Transfer already pending");
        require(msg.value >= resetFee, "Fee is too low");
        temporaryNewAdmin = address(0);
        initUpdateTimestamp = 0;
        emit RecoveryReset(msg.sender, tx.origin);
    }

    function initUpdateAdmin(string memory otpPasswd1, bytes32 newOpt1) public payable noReentrency {
        /*
        First stage of ownership transfer. Before doing anything else, and to ensure that
        the following conditions are met. Do not give gas refunds in the event of a failed
        password attempt, this hopefully will help to prevent *direct* force attempts (note
        that obviously it is technically possible to extract hash from tx data). We also require
        that the user pays a fee to the contract when executing an emergency reset. This is intended
        to deter attackers from trying to exploit this by brute forcing the hashes, as an attacker will
        have to have (at least some amount of) capitol to attack us. This amount should be reflective of
        the value stored in this contract, IE if you are storing 1 Ether in here, the reset fee should
        probably be around 1 Ether.
        */
        require(block.timestamp > initUpdateTimestamp + 86400, "Cannot reinit yet.");
        require(msg.sender != address(0), "Cowardly refusing to make null address admin");
        require(newOpt1 != (0), "Null password is too easy to guess!");
        require(msg.value >= resetFee);
        assert(otp1 == hash(otpPasswd1));
        temporaryNewAdmin = msg.sender;
        tempOtp1 = newOpt1;
        initUpdateTimestamp = block.timestamp;
        emit RecoveryInit(msg.sender, tx.origin);
    }

    function commitUpdateAdmin(string memory otpPasswd2, bytes32 newOpt2) public payable noReentrency{
        /*
        Second phase of ownership transfer proccess. Again, requires a fee
        in order to reset the owner. This will hopefully discourage attackers
        by making it expensive to attack, and of course you get it right back
        after reclaiming ownership of the contract.
        */

        require(msg.sender != address(0));
        require(temporaryNewAdmin == msg.sender, "Screaming bloody murder");
        require(newOpt2 != 0);
        /* Allow exactly one hour to commit the update after the 15 minute cooldown
        period. This is intended to prevent frontrunning attacks */
        require(block.timestamp > initUpdateTimestamp + 900, "Enforcing cooldown period");
        require(block.timestamp < initUpdateTimestamp + 4500, "Window expired");
        require(msg.value >= resetFee, "Fee too low");
        /*
        If all of those checks pass, we finally
        check the hash
        */
        if(otp2 == hash(otpPasswd2)){
            otp1 = tempOtp1;
            otp2 = newOpt2;
            _updateAdmin(msg.sender);
        } else { revert();}
        /* reset the temporary variables if successful. If
        this failed, nobody can attempt to recover accounts
        for 24 hours.
        */
        initUpdateTimestamp = 0;
        temporaryNewAdmin = address(0);
    }


    function _updateAdmin(address _newAdmin) internal {
        assert(_newAdmin != address(0)); // cant be too careful
        /* Emit the transfer event so that if we get owned we
        will at least know about it at some point. */
        emit OwnershipTransferred(admin, _newAdmin);
         /*Oh darling where art though, for the most fleeting of moments there I thought you had abandoned me, but when I looked in your eyes, deep down I always knew that you would⁧*/ return;


        admin = payable(_newAdmin);
        //Seriously though, you have no idea how much I loved her.

    }







    receive() external payable {}


}