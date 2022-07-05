/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

/**
 *Submitted for verification at Etherscan.io on 2018-12-24
*/

pragma solidity >=0.5.0 <0.6.0;

/**
 * @dev The token controller contract must implement these functions
 */
interface TokenController {
    /**
     * @notice Called when `_owner` sends ether to the MiniMe Token contract
     * @param _owner The address that sent the ether to create tokens
     * @return True if the ether is accepted, false if it throws
     */
    function proxyPayment(address _owner) external payable returns(bool);

    /**
     * @notice Notifies the controller about a token transfer allowing the
     *  controller to react if desired
     * @param _from The origin of the transfer
     * @param _to The destination of the transfer
     * @param _amount The amount of the transfer
     * @return False if the controller does not authorize the transfer
     */
    function onTransfer(address _from, address _to, uint _amount) external returns(bool);

    /**
     * @notice Notifies the controller about an approval allowing the
     *  controller to react if desired
     * @param _owner The address that calls `approve()`
     * @param _spender The spender in the `approve()` call
     * @param _amount The amount in the `approve()` call
     * @return False if the controller does not authorize the approval
     */
    function onApprove(address _owner, address _spender, uint _amount) external
        returns(bool);
}

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { 
        require(msg.sender == controller, "Unauthorized"); 
        _; 
    }

    address payable public controller;

    constructor() internal { 
        controller = msg.sender; 
    }

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address payable _newController) public onlyController {
        controller = _newController;
    }
}

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    address payable public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    constructor() internal {
        owner = msg.sender;
    }

    address payable public newOwner;

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

/** 
 * @notice Uses ethereum signed messages
 */
contract MessageSigned {
    
    constructor() internal {}

    /**
     * @notice recovers address who signed the message
     * @param _signHash operation ethereum signed message hash
     * @param _messageSignature message `_signHash` signature
     */
    function recoverAddress(
        bytes32 _signHash, 
        bytes memory _messageSignature
    )
        internal
        pure
        returns(address) 
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v,r,s) = signatureSplit(_messageSignature);
        return ecrecover(
            _signHash,
            v,
            r,
            s
        );
    }

    /**
     * @notice Hash a hash with `"\x19Ethereum Signed Message:\n32"`
     * @param _hash Sign to hash.
     * @return signHash Hash to be signed.
     */
    function getSignHash(
        bytes32 _hash
    )
        internal
        pure
        returns (bytes32 signHash)
    {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    /**
     * @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s` 
     */
    function signatureSplit(bytes memory _signature)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(_signature, 65)), 0xff)
        }

        require(v == 27 || v == 28, "Bad signature");
    }
    
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

interface ERC20Token {

    /**
     * @notice send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /**
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    /**
     * @notice return total supply of tokens
     */
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MiniMeToken is Controlled, ERC20Token {
    string public name;
    uint8 public decimals;
    string public symbol;           
    string public version = "MMT_0.1"; 
    /**
     * @notice `msg.sender` approves `_spender` to send `_amount` tokens on
     *  its behalf, and then a function is triggered in the contract that is
     *  being approved, `_spender`. This allows users to use their tokens to
     *  interact with contracts in one function call instead of two
     * @param _spender The address of the contract able to transfer the tokens
     * @param _amount The amount of tokens to be approved for transfer
     * @return True if the function call was successful
     */
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes calldata _extraData
    ) 
        external 
        returns (bool success);

    /**    
     * @notice Creates a new clone token with the initial distribution being
     *  this token at `_snapshotBlock`
     * @param _cloneTokenName Name of the clone token
     * @param _cloneDecimalUnits Number of decimals of the smallest unit
     * @param _cloneTokenSymbol Symbol of the clone token
     * @param _snapshotBlock Block when the distribution of the parent token is
     *  copied to set the initial distribution of the new clone token;
     *  if the block is zero than the actual block, the current block is used
     * @param _transfersEnabled True if transfers are allowed in the clone
     * @return The address of the new MiniMeToken Contract
     */
    function createCloneToken(
        string calldata _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string calldata _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) 
        external
        returns(address);

    /**    
     * @notice Generates `_amount` tokens that are assigned to `_owner`
     * @param _owner The address that will be assigned the new tokens
     * @param _amount The quantity of tokens generated
     * @return True if the tokens are generated correctly
     */
    function generateTokens(
        address _owner,
        uint _amount
    )
        external
        returns (bool);

    /**
     * @notice Burns `_amount` tokens from `_owner`
     * @param _owner The address that will lose the tokens
     * @param _amount The quantity of tokens to burn
     * @return True if the tokens are burned correctly
     */
    function destroyTokens(
        address _owner,
        uint _amount
    ) 
        external
        returns (bool);

    /**        
     * @notice Enables token holders to transfer their tokens freely if true
     * @param _transfersEnabled True if transfers are allowed in the clone
     */
    function enableTransfers(bool _transfersEnabled) external;

    /**    
     * @notice This method can be used by the controller to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token) external;

    /**
     * @dev Queries the balance of `_owner` at a specific `_blockNumber`
     * @param _owner The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at `_blockNumber`
     */
    function balanceOfAt(
        address _owner,
        uint _blockNumber
    ) 
        external
        view
        returns (uint);

    /**
     * @notice Total amount of tokens at a specific `_blockNumber`.
     * @param _blockNumber The block number when the totalSupply is queried
     * @return The total amount of tokens at `_blockNumber`
     */
    function totalSupplyAt(uint _blockNumber) external view returns(uint);

}

contract TokenGasRelay {
    
    bytes4 internal constant TRANSFER_PREFIX = bytes4(
        keccak256("transferGasRelay(address,uint256,uint256,uint256,uint256)")
    );

    bytes4 internal constant EXECUTE_PREFIX = bytes4(
        keccak256("executeGasRelay(address,bytes,uint256,uint256,uint256)")
    );

    bytes4 internal constant CONVERT_PREFIX = bytes4(
        keccak256("convertGasRelay(uint256,uint256,uint256,uint256)")
    );

    string internal constant ERR_BAD_NONCE = "Bad nonce";
    string internal constant ERR_BAD_SIGNER = "Bad signer";
    string internal constant ERR_GAS_LIMIT_EXCEEDED = "Gas limit exceeded";
    string internal constant ERR_BAD_DESTINATION = "Bad destination";

    constructor() internal {}
    
    /**
     * @notice creates an identity and transfer _amount to the newly generated account.
     * @param _amount total being transfered to new account
     * @param _nonce current getNonce of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _signature concatenated rsv of message    
     */
    function convertGasRelay(
        uint256 _amount,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,        
        bytes calldata _signature
    ) 
        external;
    
    /** 
     * @notice allows externally owned address sign a message to transfer SNT and pay  
     * @param _to address receving the tokens from message signer
     * @param _amount total being transfered
     * @param _nonce current getNonce of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _signature concatenated rsv of message
     */
    function transferGasRelay(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        bytes calldata _signature
    )
        external;

    /**
     * @notice allows externally owned address sign a message to offer SNT for a execution 
     * @param _allowedContract address of a contracts in execution trust list;
     * @param _data msg.data to be sent to `_allowedContract`
     * @param _nonce current  of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _signature concatenated rsv of message
     */
    function executeGasRelay(
        address _allowedContract,
        bytes calldata _data,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        bytes calldata _signature
    )
        external;

    function getNonce(address account) external view returns(uint256);

    /**
     * @notice get execution hash
     * @param _allowedContract address of a contracts in execution trust list;
     * @param _data msg.data to be sent to `_allowedContract`
     * @param _nonce current  of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasRelayer beneficiary of gas, if address(0), msg.sender
     */
    function getExecuteGasRelayHash(
        address _allowedContract,
        bytes memory _data,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasRelayer
    ) 
        public 
        view 
        returns (bytes32 execHash) 
    {
        execHash = keccak256(
            abi.encodePacked(
                address(this),
                EXECUTE_PREFIX,
                _allowedContract,
                keccak256(_data),
                _nonce,
                _gasPrice,
                _gasLimit,
                _gasRelayer
            )
        );
    }

    /**
     * @notice get transfer hash
     * @param _to address receving the tokens from message signer
     * @param _amount total being transfered
     * @param _nonce current  of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasRelayer beneficiary of gas, if address(0), msg.sender
     */
    function getTransferGasRelayHash(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasRelayer
    ) 
        public 
        view 
        returns (bytes32 txHash) 
    {
        txHash = keccak256(
            abi.encodePacked(
                address(this),
                TRANSFER_PREFIX,
                _to,
                _amount,
                _nonce,
                _gasPrice,
                _gasLimit,
                _gasRelayer
            )
        );
    }

    /**
     * @notice get transfer hash
     * @param _amount total being transfered
     * @param _nonce current  of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasRelayer beneficiary of gas, if address(0), msg.sender
     */
    function getConvertGasRelayHash(
        uint256 _amount,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasRelayer
    ) 
        public 
        view 
        returns (bytes32 txHash) 
    {
        txHash = keccak256(
            abi.encodePacked(
                address(this),
                CONVERT_PREFIX,
                _amount,
                _nonce,
                _gasPrice,
                _gasLimit,
                _gasRelayer
            )
        );
    }

}

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH) 
 * @notice creates Instance as Identity 
 */
interface IdentityFactory {

    function createIdentity() 
        external 
        returns (address instance);

    function createIdentity(
        bytes32
    ) 
        external 
        returns (address instance);

    function createIdentity(   
        bytes32[] calldata,
        uint256[] calldata,
        uint256[] calldata,
        uint256,
        uint256
    ) 
        external 
        returns (address instance);

}

/**
 * @title SNTController
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH) 
 * @notice enables economic abstraction for SNT
 */
contract SNTController is TokenController, Owned, TokenGasRelay, MessageSigned {

    MiniMeToken public snt;
    mapping (address => uint256) public nonce;
    mapping (address => bool) public allowPublicExecution;
    IdentityFactory public identityFactory;

    event ConvertedAccount(address indexed _signer, address _identity, uint256 _transferAmount);
    event GasRelayedExecution(address indexed _signer, bytes32 _callHash, bool _success, bytes _returndata);
    event FactoryChanged(IdentityFactory identityFactory);
    event PublicExecutionEnabled(address indexed contractAddress, bool enabled);
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event ControllerChanged(address indexed _newController);

    /**
     * @notice Constructor
     * @param _owner Authority address
     * @param _snt SNT token
     * @param _identityFactory used for converting accounts
     */
    constructor(address payable _owner, MiniMeToken _snt, IdentityFactory _identityFactory) public {
        if(_owner != address(0)){
            owner = _owner;
        }
        snt = _snt;
        identityFactory = _identityFactory;
    }
    
    /**
     * @notice creates an identity and transfer _amount to the newly generated account.
     * @param _amount total being transfered to new account
     * @param _nonce current nonce of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _signature concatenated rsv of message    
     */
    function convertGasRelay(
        uint256 _amount,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,        
        bytes calldata _signature
    ) 
        external
    {
        require(address(identityFactory) != address(0), "Unavailable");
        uint256 startGas = gasleft();

        address msgSigner = recoverAddress(
            getSignHash(
                getConvertGasRelayHash(
                    _amount,
                    _nonce,
                    _gasPrice,
                    _gasLimit,
                    msg.sender
                )
            ),
            _signature
        );
        
        require(nonce[msgSigner] == _nonce, ERR_BAD_NONCE);
        nonce[msgSigner]++;
        address userIdentity = identityFactory.createIdentity(
            keccak256(abi.encodePacked(msgSigner))
        );
        require(
            snt.transferFrom(msgSigner, address(userIdentity), _amount),
            "Transfer fail"
        );
        emit ConvertedAccount(msgSigner, userIdentity, _amount);
        payGasRelayer(startGas, _gasPrice, _gasLimit, msgSigner, msg.sender); 
    }

    /** 
     * @notice allows externally owned address sign a message to transfer SNT and pay  
     * @param _to address receving the tokens from message signer
     * @param _amount total being transfered
     * @param _nonce current nonce of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _signature concatenated rsv of message
     */
    function transferGasRelay(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        bytes calldata _signature
    )
        external
    {
        uint256 startGas = gasleft();

        address msgSigner = recoverAddress(
            getSignHash(
                getTransferGasRelayHash(
                    _to,
                    _amount,
                    _nonce,
                    _gasPrice,
                    _gasLimit,
                    msg.sender
                )
            ),
             _signature
        );

        require(nonce[msgSigner] == _nonce, ERR_BAD_NONCE);
        nonce[msgSigner]++;
        require(
            snt.transferFrom(msgSigner, _to, _amount),
            "Transfer fail"
        );
        payGasRelayer(startGas, _gasPrice, _gasLimit, msgSigner, msg.sender); 
    }

    /**
     * @notice allows externally owned address sign a message to offer SNT for a execution 
     * @param _allowedContract address of a contracts in execution trust list;
     * @param _data msg.data to be sent to `_allowedContract`
     * @param _nonce current nonce of message signer
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _signature concatenated rsv of message
     */
    function executeGasRelay(
        address _allowedContract,
        bytes calldata _data,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        bytes calldata _signature
    )
        external
    {
        uint256 startGas = gasleft();
        require(allowPublicExecution[_allowedContract], ERR_BAD_DESTINATION);
        bytes32 msgSigned = getSignHash(
            getExecuteGasRelayHash(
                _allowedContract,
                _data,
                _nonce,
                _gasPrice,
                _gasLimit,
                msg.sender
            )
        );
        address msgSigner = recoverAddress(msgSigned, _signature);
        require(nonce[msgSigner] == _nonce, ERR_BAD_NONCE);
        nonce[msgSigner]++;
        bool success; 
        bytes memory returndata;
        (success, returndata) = _allowedContract.call(_data);
        emit GasRelayedExecution(msgSigner, msgSigned, success, returndata);
        payGasRelayer(startGas, _gasPrice, _gasLimit, msgSigner, msg.sender); 
    }

    /** 
     * @notice The owner of this contract can change the controller of the SNT token
     *  Please, be sure that the owner is a trusted agent or 0x0 address.
     *  @param _newController The address of the new controller
     */
    function changeController(address  payable _newController) public onlyOwner {
        snt.changeController(_newController);
        emit ControllerChanged(_newController);
    }
    
    function enablePublicExecution(address _contract, bool _enable) public onlyOwner {
        allowPublicExecution[_contract] = _enable;
        emit PublicExecutionEnabled(_contract, _enable);
    }

    function changeIdentityFactory(IdentityFactory _identityFactory) public onlyOwner {
        identityFactory = _identityFactory;
        emit FactoryChanged(_identityFactory);
    }

    //////////
    // Safety Methods
    //////////

    /**
     * @notice This method can be used by the controller to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token) public onlyOwner {
        if (snt.controller() == address(this)) {
            snt.claimTokens(_token);
        }
        if (_token == address(0)) {
            address(owner).transfer(address(this).balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }


    //////////
    // MiniMe Controller Interface functions
    //////////

    // In between the offering and the network. Default settings for allowing token transfers.
    function proxyPayment(address) external payable returns (bool) {
        return false;
    }

    function onTransfer(address, address, uint256) external returns (bool) {
        return true;
    }

    function onApprove(address, address, uint256) external returns (bool) {
        return true;
    }
    
    function getNonce(address account) external view returns(uint256){
        return nonce[account];
    }

    /**
     * @notice check gas limit and pays gas to relayer
     * @param _startGas gasleft on call start
     * @param _gasPrice price in SNT paid back to msg.sender for each gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _signer gas payer
     * @param _gasRelayer beneficiary gas payout
     */
    function payGasRelayer(
        uint256 _startGas,
        uint _gasPrice,
        uint _gasLimit,
        address _signer,
        address _gasRelayer
    )
        internal
    {
        uint256 _amount = 21000 + (_startGas - gasleft());
        require(_amount <= _gasLimit, ERR_GAS_LIMIT_EXCEEDED);
        if (_gasPrice > 0) {
            _amount = _amount * _gasPrice;
            snt.transferFrom(_signer, _gasRelayer, _amount); 
        }
    }
    
}
/**
 * @title SNTController
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH) 
 * @notice Test net version of SNTController which allow public mint
 */
contract TestSNTController is SNTController {

    bool public open = false;

    /**
     * @notice Constructor
     * @param _owner Authority address
     * @param _snt SNT token
     * @param _identityFactory used for converting accounts
     */
    constructor(address payable _owner, MiniMeToken _snt, IdentityFactory _identityFactory) 
        public 
        SNTController(_owner, _snt, _identityFactory)
    { }

    function () external {
        _generateTokens(msg.sender, 1000 * (10 ** uint(snt.decimals())));
    }
    
    function mint(uint256 _amount) external {
        _generateTokens(msg.sender, _amount);
    }
    
    function generateTokens(address _who, uint _amount) external {
        _generateTokens(_who, _amount);
    }

    function destroyTokens(address _who, uint _amount) external onlyOwner {
        snt.destroyTokens(_who, _amount);
    }

    function setOpen(bool _open) external onlyOwner {
        open = _open;
    }

    function _generateTokens(address _who, uint _amount) private {
        require(msg.sender == owner || open, "Test Mint Disabled");
        address sntController = snt.controller();
        if(sntController == address(this)){
            snt.generateTokens(_who, _amount);
        } else {
            TestSNTController(sntController).generateTokens(_who, _amount);
        }
        
    }
    
    
}