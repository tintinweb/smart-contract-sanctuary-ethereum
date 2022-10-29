pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract wallet_saver {
    address public owner;
    bytes32 public tx_content_hash;
    uint256 public block_time_start;
    uint256 time_delay;
    address panic_address;
    address[] erc20s;

    IERC20 public token;

    modifier _is_owner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        uint256 _time_delay,
        address _panic_address,
        address[] memory _erc20s
    ) {
        owner = msg.sender;
        time_delay = _time_delay;
        panic_address = _panic_address;
        erc20s = _erc20s;
    }

    function queue(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) public _is_owner {
        block_time_start = block.timestamp;
        tx_content_hash = keccak256(abi.encodePacked(_to, _value, _data));
    }

    function execute_call(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) public payable _is_owner {
        require(
            block.timestamp > block_time_start + time_delay,
            "You can only execute after the time delay"
        );
        require(
            keccak256(abi.encodePacked(_to, _value, _data)) == tx_content_hash
        );
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "something went wrong - tx failed");
    }

    function revert_txn() public _is_owner {
        block_time_start = 999999999999999999999999999999999999;
        tx_content_hash = bytes32(0);
    }

    function add_tokens(address[] memory _erc20s) public _is_owner {
        for (uint8 i; i < _erc20s.length; i++) {
            erc20s.push(_erc20s[i]);
        }
    }

    function panic() public _is_owner {
        for (uint8 i; i < erc20s.length; i++) {
            IERC20(erc20s[i]).transfer(
                panic_address,
                IERC20(erc20s[i]).balanceOf(address(this))
            );
        }
    }

    // function change_owner(address new_owner) public _is_owner {
    //     owner = new_owner;
    // }

    receive() external payable {}
}