/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

pragma solidity ^0.5.0;

contract Token {
    string  public name = "PornCoin";
    string  public symbol = "PC";
    uint256 public totalSupply;
    uint8   public decimals = 0;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) public {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }
    /////////
    struct Comment {
        bool like;
        string content;
    }
    struct Post {
        string type_;
        string title;
        string content;
        string author;
        address author_addr;
        uint pb_value;
        uint post_time;
        uint id;
    }
    Post[] public posts;
    Comment[] public comments;
    mapping(address => uint[]) public account_to_post;
    mapping(uint => address) public post_to_account;
    mapping(uint => uint[]) public post_to_comment;
    mapping(uint => address) public comment_to_account;
    mapping(address => string) public addrToName;
    mapping(address => uint256) public addrToTime;
    mapping (address => mapping (address => uint256)) allowed;
    event NewPostAdded(uint post_id, uint comment_id, address owner);
    function join(address addr, string memory name) public{
        addrToName[addr] = name;
        balanceOf[addr] = 100000;
        addrToTime[addr] = block.timestamp;
    }
    function get_p_value(address addr) view public returns(uint256) {
        return balanceOf[addr];
    }
    function new_post(address addr,string memory _type_, string memory title, string memory text) public{
        if (balanceOf[addr] <= 0 ) {
            return;
        }
        uint id = posts.length - 1;
        Post memory post = Post({
            type_: _type_,
            title: title,
            content: text, 
            author: addrToName[addr],
            author_addr: addr,
            pb_value: bytes(text).length,
            post_time: block.timestamp,
            id: id
        });
        posts.push(post);
        post_to_account[id] = addr;
        account_to_post[addr].push(id);
        uint256 a = bytes(text).length;
        transfer(addr,10*a);
        emit NewPostAdded(id, 0, msg.sender);
    }
    function new_comment(address _from, uint post_id, bool _like, string memory text,uint256 value) public{
        if(balanceOf[_from]<value){
            return;
        }
        Comment memory comment = Comment({like: _like, content: text});
        comments.push(comment);
        uint comment_id = comments.length - 1;

        post_to_comment[post_id].push(comment_id);
        comment_to_account[comment_id] = _from;
        if(_like){
            transferFrom(_from, post_to_account[post_id], value);
        }
        else{
            if(balanceOf[post_to_account[post_id]]<value){
                transferFrom(post_to_account[post_id],msg.sender, balanceOf[post_to_account[post_id]]);
            }
            else{
                transferFrom(post_to_account[post_id],msg.sender, value);
            }
            transferFrom(_from,msg.sender, value);
        }
        emit NewPostAdded(post_id, comment_id, _from);
    }
    /////////
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}