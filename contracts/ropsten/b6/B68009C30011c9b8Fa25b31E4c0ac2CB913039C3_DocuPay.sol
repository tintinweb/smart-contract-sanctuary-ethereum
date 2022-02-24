/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract DocuPay {
  struct Document {
    uint256 docId;
    address payable uploader;
    string title;
    uint256 date;
    string description;
    uint256 fee;
    string file;
    uint256 votes;
    uint256 favourites;
  }

  struct Comment {
    uint256 commentId;
    address commenter;
    uint256 date;
    string commentMsg;
    uint256 likes;
  }

  Document[] public documents;
  Comment[] public comments;

  // Users have a name and reputation; documents they have uploaded, purchased, voted on, and favourited are also stored
  mapping(address => string) public name;
  mapping(address => uint256) public reputation;
  mapping(address => uint256[]) public documentsUploaded;
  mapping(address => uint256[]) public documentsPurchased;
  mapping(address => uint256[]) public documentsUpvoted;
  mapping(address => uint256[]) public documentsDownvoted;
  mapping(address => uint256[]) public documentsFavourited;
  mapping(uint256 => uint256[]) public commentsOnDocument;
  mapping(address => uint256[]) public commentsLiked;

  // Getters
  function getDocumentById(uint256 docId) public view returns(Document memory) {
    // The document's index in the array starts from zero, which is the ID minus one
    return documents[docId - 1];
  }

  function getName(address user) public view returns(string memory) {
    return name[user];
  }

  function getReputation(address user) public view returns(uint256) {
    return reputation[user];
  }

  function getTotalDocumentsCount() public view returns(uint256) {
    return documents.length;
  }

  function getDocumentsUploadedCount(address user) public view returns(uint256) {
    return documentsUploaded[user].length;
  }

  function getDocumentUploaded(address user, uint256 docIndex) public view returns(uint256) {
    return documentsUploaded[user][docIndex];
  }

  function getDocumentsPurchasedCount(address user) public view returns(uint256) {
    return documentsPurchased[user].length;
  }

  function getDocumentPurchased(address user, uint256 docIndex) public view returns(uint256) {
    return documentsPurchased[user][docIndex];
  }

  function getDocumentsFavouritedCount(address user) public view returns(uint256) {
    return documentsFavourited[user].length;
  }

  function getDocumentFavourited(address user, uint256 docIndex) public view returns(uint256) {
    return documentsFavourited[user][docIndex];
  }

  function getCommentById(uint256 commentId) public view returns(Comment memory) {
    uint256 commentIndex = 0;

    // Search for a matching comment ID
    for (uint256 i = 0; i < comments.length; i++) {
      if (comments[i].commentId == commentId)
        commentIndex = i;
    }

    return comments[commentIndex];
  }

  function getCommentCount(uint256 docId) public view returns(uint256) {
    return commentsOnDocument[docId].length;
  }

  function getCommentOnDocument(uint256 docId, uint256 commentId) public view returns(uint256) {
    uint256 commentIndex = 0;

    // Search for a matching comment ID
    for (uint256 i = 0; i < commentsOnDocument[docId].length; i++) {
      if (commentsOnDocument[docId][i] == commentId)
        commentIndex = i;
    }

    return commentsOnDocument[docId][commentIndex];
  }

  // Editing the Display Name
  function changeName(string memory newName) public {
    require(bytes(newName).length > 0 && bytes(newName).length <= 35, "Name length must be above 0 and below 35 chars");

    name[msg.sender] = newName;
  }

  // Uploading a Document
  function uploadDocument(string memory title, uint256 date, string memory description, uint256 fee, string memory file) public {
    require(bytes(title).length > 0 && bytes(title).length <= 25, "Title length must be above 0 and above 25 chars");
    require(bytes(description).length > 0 && bytes(description).length <= 1000, "Description length must be above 0 and under 1000 chars");
    require(fee >= 0 wei, "Fee cannot be negative");

    // Add the document
    documents.push(Document(documents.length + 1, payable(msg.sender), title, date, description, fee, file, 0, 0));
    documentsUploaded[msg.sender].push(documents.length + 1);
  }

  // Purchasing a Document
  function purchaseDocument(uint256 docId) public {
    documentsPurchased[msg.sender].push(docId);
  }

  function isDocumentPurchased(uint256 docId) public view returns(bool) {
    // Check if the user has purchased the document previously
    for (uint256 i = 0; i < documentsPurchased[msg.sender].length; i++) {
      if (documentsPurchased[msg.sender][i] == docId)
        return true;
    }

    return false;
  }

  function canView(uint256 docId) public view returns(bool) {
    // If the user uploaded the document or they have purchased the document before, they can view it
    if (msg.sender == getDocumentById(docId).uploader || isDocumentPurchased(docId))
      return true;

    return false;
  }

  // Voting On a Document
  function upvoteDocument(uint256 docId) public {
    // Ensure that the voter is not the uploader
    require(msg.sender != getDocumentById(docId).uploader, "You cannot upvote your own document");

    // Remove the downvote from the document first, if any
    if (isDocumentDownvoted(docId) == true) {
      uint256 docIndex = 0;

      for (uint256 i = 0; i < documentsDownvoted[msg.sender].length; i++) {
        if (documentsDownvoted[msg.sender][i] == docId)
          docIndex = i;
      }

      // Move the document from the last position to the deleted document's position, then pop the array to shrink it
      documentsDownvoted[msg.sender][docIndex] = documentsDownvoted[msg.sender][documentsDownvoted[msg.sender].length - 1];
      documentsDownvoted[msg.sender].pop();
    }

    // Increase the number of votes and the uploader's reputation
    documentsUpvoted[msg.sender].push(docId);
    documents[docId - 1].votes += 1;
    reputation[documents[docId - 1].uploader] += 10;
  }

  function downvoteDocument(uint256 docId) public {
    // Ensure that the voter is not the uploader
    require(msg.sender != getDocumentById(docId).uploader, "You cannot downvote your own document");

    // Remove any upvotes from the document first
    if (isDocumentUpvoted(docId) == true) {
      uint256 docIndex = 0;

      for (uint256 i = 0; i < documentsUpvoted[msg.sender].length; i++) {
        if (documentsUpvoted[msg.sender][i] == docId)
          docIndex = i;
      }

      documentsUpvoted[msg.sender][docIndex] = documentsUpvoted[msg.sender][documentsUpvoted[msg.sender].length - 1];
      documentsUpvoted[msg.sender].pop();
    }

    // Decrease the number of votes
    documentsDownvoted[msg.sender].push(docId);

    // Prevent the document's vote count from going below zero
    if ((documents[docId - 1].votes -= 1) <= 0)
      documents[docId - 1].votes == 0;
    else
      documents[docId - 1].votes -= 1;

    // Check if the user's reputation will be less than zero once their reputation has been decreased
    if ((reputation[documents[docId - 1].uploader] -= 5) <= 0)
      reputation[documents[docId - 1].uploader] == 0;
    else
      reputation[documents[docId - 1].uploader] -= 5;
  }

  function removeVoteFromDocument(uint256 docId) public {
    // Ensure that the voter has either upvoted or downvoted on this document
    require(isDocumentUpvoted(docId) == true || isDocumentDownvoted(docId) == true, "You have not voted on this document");

    uint256 docIndex = 0;

    if (isDocumentUpvoted(docId) == true) {
      // Search for the document's position in the array
      for (uint256 i = 0; i < documentsUpvoted[msg.sender].length; i++) {
        if (documentsUpvoted[msg.sender][i] == docId)
          docIndex = i;
      }

      // Remove the vote from the list of documents upvoted
      documentsUpvoted[msg.sender][docIndex] = documentsUpvoted[msg.sender][documentsUpvoted[msg.sender].length - 1];
      documentsUpvoted[msg.sender].pop();

      // Reduce the number of votes
      if ((documents[docId - 1].votes -= 1) <= 0)
        documents[docId - 1].votes == 0;
      else
        documents[docId - 1].votes -= 1;

      // Check if the user's reputation will be less than zero once their reputation has been decreased
      if ((reputation[documents[docId - 1].uploader] -= 5) <= 0)
        reputation[documents[docId - 1].uploader] == 0;
      else
        reputation[documents[docId - 1].uploader] -= 5;
    } else if (isDocumentDownvoted(docId) == true) {
      // Search for the document's position in the array
      for (uint256 i = 0; i < documentsDownvoted[msg.sender].length; i++) {
        if (documentsDownvoted[msg.sender][i] == docId)
          docIndex = i;
      }

      // Remove the vote from the list of documents downvoted
      documentsDownvoted[msg.sender][docIndex] = documentsDownvoted[msg.sender][documentsDownvoted[msg.sender].length - 1];
      documentsDownvoted[msg.sender].pop();

      // Increase the uploader's reputation
      reputation[documents[docId - 1].uploader] += 5;
    }
  }

  function isDocumentUpvoted(uint256 docId) public view returns(bool) {
    // Check if the user has upvoted the document
    for (uint256 i = 0; i < documentsUpvoted[msg.sender].length; i++) {
      if (documentsUpvoted[msg.sender][i] == docId)
        return true;
    }

    return false;
  }

  function isDocumentDownvoted(uint256 docId) public view returns(bool) {
    // Check if the user has downvoted the document
    for (uint256 i = 0; i < documentsDownvoted[msg.sender].length; i++) {
      if (documentsDownvoted[msg.sender][i] == docId)
        return true;
    }

    return false;
  }

  // Favouriting a Document
  function favouriteDocument(uint256 docId) public {
    // Check if the document has already been favourited
    bool isDocumentFound = false;

    for (uint256 i = 0; i < documentsFavourited[msg.sender].length; i++) {
      if (documentsFavourited[msg.sender][i] == docId)
        isDocumentFound = true;
    }

    require(isDocumentFound == false, "You have already favourited this document");

    // Users can favourite a document to save and look at later, whether they have purchased it or not
    documentsFavourited[msg.sender].push(docId);

    // Increase the favourites count
    documents[docId - 1].favourites += 1;
  }

  function unfavouriteDocument(uint256 docId) public {
    // Check if the document has been favourited first
    uint256 docIndex = 0;
    bool isDocumentFound = false;

    for (uint256 i = 0; i < documentsFavourited[msg.sender].length; i++) {
      if (documentsFavourited[msg.sender][i] == docId) {
        docIndex = i;
        isDocumentFound = true;
      }
    }

    require(isDocumentFound == true, "You have not favourited this document");

    // Remove the document ID from the array of favourited documents
    documentsFavourited[msg.sender][docIndex] = documentsFavourited[msg.sender][documentsFavourited[msg.sender].length - 1];
    documentsFavourited[msg.sender].pop();

    // Reduce the favourites count
    documents[docId - 1].favourites -= 1;
  }

  function isDocumentFavourited(uint256 docId) public view returns(bool) {
    // Check if the user has favourited the document
    for (uint256 i = 0; i < documentsFavourited[msg.sender].length; i++) {
      if (documentsFavourited[msg.sender][i] == docId)
        return true;
    }

    return false;
  }

  // Commenting On a Document
  function sendComment(uint256 docId, uint256 date, string memory commentMsg) public {
    require(bytes(commentMsg).length > 0 && bytes(commentMsg).length < 500, "Comment length must be above 0 and under 500 chars");

    // Determine what ID the comment will have
    if (comments.length == 0)
      comments.push(Comment(comments.length + 1, msg.sender, date, commentMsg, 0));
    else
      comments.push(Comment(comments[comments.length].commentId + 1, msg.sender, date, commentMsg, 0));

    // Add the comment
    return commentsOnDocument[docId].push(comments.length);
  }

  function deleteComment(uint256 docId, uint256 commentId) public {
    // Search for and delete the comment in the "comments" array
    uint256 commentIndex = 0;

    for (uint256 i = 0; i < comments.length; i++) {
      if (comments[i].commentId == commentId)
        commentIndex = i;
    }

    comments[commentIndex] = comments[comments.length - 1];
    comments.pop();

    // Search for and delete the comment in the "commentsOnDocument" mapping
    for (uint256 i = 0; i < commentsOnDocument[docId].length; i++) {
      if (commentsOnDocument[docId][i] == commentId)
        commentIndex = i;
    }

    commentsOnDocument[docId][commentIndex] = commentsOnDocument[docId][commentsOnDocument[docId].length - 1];
    commentsOnDocument[docId].pop();
  }

  function likeComment(uint256 commentId) public {
    // Ensure that the voter is not the commenter
    require(msg.sender != getCommentById(commentId).commenter, "You cannot like your own comment");

    // Increase the number of likes and the commenter's reputation
    commentsLiked[msg.sender].push(commentId);
    comments[commentId - 1].likes += 1;
    reputation[comments[commentId - 1].commenter] += 1;
  }

  function removeLikeFromComment(uint256 commentId) public {
    // Ensure that the voter has liked this comment
    require(isCommentLiked(commentId) == true, "You have not liked this comment");

    uint256 commentIndex = 0;

    // Search for the comment's position in the array
    for (uint256 i = 0; i < commentsLiked[msg.sender].length; i++) {
      if (commentsLiked[msg.sender][i] == commentId)
        commentIndex = i;
    }

    // Remove the like from the list of comments liked
    commentsLiked[msg.sender][commentIndex] = commentsLiked[msg.sender][commentsLiked[msg.sender].length - 1];
    commentsLiked[msg.sender].pop();

    // Reduce the number of likes
    if ((comments[commentId - 1].likes -= 1) <= 0)
      comments[commentId - 1].likes == 0;
    else
      comments[commentId - 1].likes -= 1;

    // Check if the commenter's reputation will be less than zero once their reputation has been decreased
    if ((reputation[comments[commentId - 1].commenter] -= 1) <= 0)
      reputation[comments[commentId - 1].commenter] == 0;
    else
      reputation[comments[commentId - 1].commenter] -= 1;
  }

  function isCommentLiked(uint256 commentId) public view returns(bool) {
    // Check if the user has liked the comment
    for (uint256 i = 0; i < commentsLiked[msg.sender].length; i++) {
      if (commentsLiked[msg.sender][i] == commentId)
        return true;
    }

    return false;
  }
}