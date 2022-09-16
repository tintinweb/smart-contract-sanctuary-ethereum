/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract Voting is IERC20 {
    uint256 public constant MAX_VOTES_PER_VOTER = 3;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "MVoting";
    string public symbol = "MOV";
    uint8 public decimals = 18;

    struct Movie {
        uint256 id;
        string title;
        string cover;
        uint256 votes;
    }
    event Voted();
    event NewMovie();

    mapping(uint256 => Movie) public movies;
    uint256 public moviesCount;

    mapping(address => uint256) public votes;

    constructor() {
        moviesCount = 0;
        totalSupply = 1000000000 * (10**uint256(decimals));
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function vote(uint256 _movieID) public {
        require(
            votes[msg.sender] < MAX_VOTES_PER_VOTER,
            "Voter has no votes left."
        );
        require(
            _movieID > 0 && _movieID <= moviesCount,
            "Movie ID is out of range."
        );

        votes[msg.sender]++;
        movies[_movieID].votes++;

        emit Voted();
    }

    function addMovie(string memory _title, string memory _cover) public {
        moviesCount++;

        Movie memory movie = Movie(moviesCount, _title, _cover, 0);
        movies[moviesCount] = movie;

        emit NewMovie();
        vote(moviesCount);
    }
}