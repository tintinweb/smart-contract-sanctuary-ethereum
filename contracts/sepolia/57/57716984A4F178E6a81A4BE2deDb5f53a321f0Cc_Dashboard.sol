// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error Dashboard__NotEnoughETHToAddPost();
error Dashboard__NotEnoughETHToBuyItemFromThePost();

contract Dashboard {
  address private immutable i_owner;
  uint256 private immutable i_minEntranceFee;
  uint256 public totalPost;
  uint256[] public postIds;

  constructor(uint256 minEntranceFee) payable {
    i_owner = payable(msg.sender);
    i_minEntranceFee = minEntranceFee;
  }

  event ItemAdded(
    address indexed sender,
    string description,
    string title,
    uint256 price,
    uint256 id
  );

  event ItemBuyed(address indexed buyer, uint256 id, uint256 price);

  struct Post {
    address sender;
    string description;
    string title;
    uint256 price;
    uint256 id;
  }

  mapping(uint256 => Post) posts;

  function addPost(
    string memory _description,
    string memory _title,
    uint256 _price
  ) public payable {
    if (msg.value < i_minEntranceFee) {
      revert Dashboard__NotEnoughETHToAddPost();
    }

    Post storage newPost = posts[totalPost];

    newPost.description = _description;
    newPost.title = _title;
    newPost.price = _price;
    newPost.sender = msg.sender;
    newPost.id = totalPost;

    postIds.push(totalPost);
    emit ItemAdded(msg.sender, _description, _title, _price, totalPost);

    totalPost += 1;
  }

  function BuyItemFromThePost(uint256 postId) public payable {
    if (msg.value < posts[postId].price) {
      revert Dashboard__NotEnoughETHToBuyItemFromThePost();
    }

    payable(posts[postId].sender).transfer(msg.value);

    emit ItemBuyed(msg.sender, postId, msg.value);

    delete (posts[postId]);
  }
}