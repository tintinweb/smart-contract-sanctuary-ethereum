/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MovieRating {

  struct Movie {
    string name;
    uint rating;
  }

  mapping(string => Movie) movies;
  string[] movieNames; // New variable to store movie names

  function addMovie(string memory name, uint rating) public {
    movies[name] = Movie(name, rating);
    movieNames.push(name); // Add movie name to the array
  }

  function getMovie(string memory name) public view returns (Movie memory) {
    return movies[name];
  }

  function filterMovies(uint rating) public view returns (Movie[] memory) {
    if (rating < 0) {
      revert();
    }
    uint count = movieNames.length; // Get the number of movies
    Movie[] memory filteredMovies = new Movie[](count);
    uint filteredCount = 0; // Track the number of filtered movies
    for (uint i = 0; i < count; i++) {
      Movie memory movie = movies[movieNames[i]];
      if (movie.rating >= rating) {
        filteredMovies[filteredCount] = movie;
        filteredCount++;
      }
    }
    // Resize the filteredMovies array to remove any empty slots
    assembly {
      mstore(filteredMovies, filteredCount)
    }
    return filteredMovies;
  }
}