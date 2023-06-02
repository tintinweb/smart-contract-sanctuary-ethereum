contract NFTweet {

address public x;

function mint() public {
require(x == address(0));
x = msg.sender;}

function transfer(address to) public {
require(x == msg.sender);
x = to;}}