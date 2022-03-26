/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

pragma solidity *0.4.11;

contract Token {

    /// @return total amount of tokens
    // 전체 토큰 수 반환 함수
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    // 특정 주소(_owner)가 보유한 토큰 수 반환
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    // 특정 수신 주소(_to)로 토큰 전달 결과 값 반환(성공: true, 실패: false)
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    //송신 주소에서 수신주소로 토큰을 전송한 결과 반환(성공:true, 실패:false)
    //이를 위해 approve()를 통해 사전 승인이 필요
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    // 발신 주소에서 일정 토큰을 권한자(_spender)에게 인출할 수 있도록 권한 부여
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    // 토큰 소유자(_owner)가 토큰 수신자(_spender)에게 인출을 허락한 토큰 수 반환
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    // 토큰 전송 이벤트 함수
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // 권한 부여 이벤트 함수 
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract DFLVCoin is StandardToken { // 콘트렉트명 변경

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   // 토큰명에 대한 변수선언 
    uint8 public decimals;                // 토큰의 소숫점 이라 값 단위 변수 선언
    string public symbol;                 // 토큰의 Symbol 변수 선언
    string public version = 'H1.0';       // 버전 정보 변수 선언 
    uint256 public unitsOneEthCanBuy;     // 1 ETH로 구매가능한 토큰의 수 정의 변수 선언 
    uint256 public totalEthInWei;         // 총 발행 토큰 수(WEI 단위)
    address public fundsWallet;           // ETH를 받을 이더리움 주소

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    function DFLVCoin() {
        balances[msg.sender] = 1000000000000000000000;               // 컨트랙트 Owner가 받을 전체 토큰 수 (WEI 단위)
        totalSupply = 1000000000000000000000;                        // 전체 공급 토큰 수 (WEI 단위)
        name = "DFLVCoin";                                           // 표시용 토큰명
        decimals = 18;                                               // 토큰의 소숫점 이라 값 단위
        symbol = "DFLV";                                             // 토큰 Symbol
        unitsOneEthCanBuy = 10;                                      // 1 ETH로 구매 가능한 토큰 수 (1 ETH = 10DFLV)
        fundsWallet = msg.sender;                                    // The owner of the contract gets ETH
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);                               
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}