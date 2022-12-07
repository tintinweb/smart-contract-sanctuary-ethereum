// SPDX-License-Identifier: --BCOM--

pragma solidity =0.8.17;

import "./VerseClaimer.sol";

contract VerseToken {

    string public constant name = "Verse";
    string public constant symbol = "VERSE";
    uint8 public constant decimals = 18;

    VerseClaimer public immutable claimer;

    address constant ZERO_ADDRESS = address(0);
    uint256 constant UINT256_MAX = type(uint256).max;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    constructor(
        uint256 _initialSupply,
        uint256 _minimumTimeFrame,
        bytes32 _merkleRoot
    ) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        claimer = new VerseClaimer(
            _merkleRoot,
            _minimumTimeFrame,
            address(this)
        );

        _mint(
            address(claimer),
            _initialSupply
        );
    }

    function _mint(
        address _to,
        uint256 _value
    )
        internal
    {
        totalSupply =
        totalSupply + _value;

        unchecked {
            balanceOf[_to] =
            balanceOf[_to] + _value;
        }

        emit Transfer(
            ZERO_ADDRESS,
            _to,
            _value
        );
    }

    function burn(
        uint256 _value
    )
        external
    {
        _burn(
            msg.sender,
            _value
        );
    }

    function _burn(
        address _from,
        uint256 _value
    )
        internal
    {
        unchecked {
            totalSupply =
            totalSupply - _value;
        }

        balanceOf[_from] =
        balanceOf[_from] - _value;

        emit Transfer(
            _from,
            ZERO_ADDRESS,
            _value
        );
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _value
    )
        private
    {
        allowance[_owner][_spender] = _value;

        emit Approval(
            _owner,
            _spender,
            _value
        );
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    )
        private
    {
        balanceOf[_from] =
        balanceOf[_from] - _value;

        unchecked {
            balanceOf[_to] =
            balanceOf[_to] + _value;
        }

        emit Transfer(
            _from,
            _to,
            _value
        );
    }

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _value
        );

        return true;
    }

    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            allowance[msg.sender][_spender] + _addedValue
        );

        return true;
    }

    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            allowance[msg.sender][_spender] - _subtractedValue
        );

        return true;
    }

    function transfer(
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        _transfer(
            msg.sender,
            _to,
            _value
        );

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        if (allowance[_from][msg.sender] != UINT256_MAX) {
            allowance[_from][msg.sender] -= _value;
        }

        _transfer(
            _from,
            _to,
            _value
        );

        return true;
    }

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _deadline >= block.timestamp,
            "VerseToken: PERMIT_CALL_EXPIRED"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        _owner,
                        _spender,
                        _value,
                        nonces[_owner]++,
                        _deadline
                    )
                )
            )
        );

        if (uint256(_s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("VerseToken: INVALID_SIGNATURE");
        }

        address recoveredAddress = ecrecover(
            digest,
            _v,
            _r,
            _s
        );

        require(
            recoveredAddress != ZERO_ADDRESS &&
            recoveredAddress == _owner,
            "VerseToken: INVALID_SIGNATURE"
        );

        _approve(
            _owner,
            _spender,
            _value
        );
    }
}