// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Optional - search course

// Add Course
// Total Instructors
// Total Students
// Total Courses
// Students by instructor
// Students by course
// Course AlreadyPurchased by student
// Get Trending course based on number of students

contract Agora {
    struct Course {
        uint256 uniqueId;
        address owner;
        string title;
        string description;
        address[] consumers;
        uint256 price;
        string image;
        string createdOn;
        string createdBy;
        string level;
        string category;
        string language;
        bool certificate;
    }
    struct Instructor {
        address addressOfInstructor;
        address[] students;
    }
    event Log(string message);
    event Log(address id);
    // event Log(address indexed indexedtype);
    mapping(uint256 => Course) public courses;
    // mapping(uint256 => address) public instructors;

    mapping(uint256 => Instructor) public instructors;
    mapping(uint256 => address) public students;

    uint256 public uniqueId = 0;
    uint256 public numberOfCourses = 0;
    uint256 public numberOfInstructors = 0;
    uint256 public numberOfStudents = 0;

    function alreadyPurchased(uint256 _id) public view returns (bool) {
        bool purchased = false;
        for (uint256 i = 0; i < courses[_id].consumers.length; i++) {
            if (courses[_id].consumers[i] == msg.sender) {
                purchased = true;
                break;
            }
        }
        return purchased;
    }

    function createCourse(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _price,
        string memory _image,
        string memory createdOn,
        string memory createdBy,
        string memory level,
        string memory category,
        string memory language,
        bool certificate
    ) public returns (uint256) {
        Course storage course = courses[numberOfCourses];
        Instructor storage instructor = instructors[numberOfInstructors];

        course.uniqueId = uniqueId++;
        course.owner = _owner;
        course.title = _title;
        course.description = _description;
        course.price = _price;
        course.image = _image;
        course.createdOn = createdOn;
        course.createdBy = createdBy;
        course.language = language;
        course.level = level;
        course.certificate = certificate;
        course.category = category;
        numberOfCourses++;
        bool alreadyInstructor = false;

        emit Log(_owner);
        for (uint256 i = 0; i < numberOfInstructors; i++) {
            emit Log("Inside loop instructor:");

            if (instructors[i].addressOfInstructor == _owner) {
                emit Log("Instructor is already present");
                alreadyInstructor = true;
                break;
            }
        }
        if (!alreadyInstructor) {
            instructor.addressOfInstructor = _owner;
            numberOfInstructors++;
        }

        return numberOfCourses - 1;
    }

    function purchaseCourse(uint256 _id) public payable {
        bool alreadyStudent = false;
        for (uint256 i = 0; i < numberOfStudents; i++) {
            if (msg.sender == students[i]) {
                emit Log("Student is already present");
                alreadyStudent = true;
                break;
            }
        }
        if (!alreadyStudent) {
            students[numberOfStudents] = msg.sender;
            numberOfStudents++;
        }

        uint256 amount = msg.value;

        Course storage course = courses[_id];

        course.consumers.push(msg.sender);

        (bool sent, ) = payable(course.owner).call{value: amount}("");

        uint256 id;
        for (uint256 i = 0; i < numberOfInstructors; i++) {
            if (instructors[i].addressOfInstructor == courses[_id].owner) {
                id = i;
            }
        }
        address[] memory studentsOfInstructor = getStudentsByInstructor(id);
        alreadyStudent = false;
        for (uint256 i = 0; i < studentsOfInstructor.length; i++) {
            if (studentsOfInstructor[i] == msg.sender) {
                alreadyStudent = true;
                break;
            }
        }
        if (!alreadyStudent) {
            instructors[id].students.push(msg.sender);
        }
    }

    function getCourses() public view returns (Course[] memory) {
        Course[] memory allCourses = new Course[](numberOfCourses);

        for (uint256 i = 0; i < numberOfCourses; i++) {
            Course storage item = courses[i];
            allCourses[i] = item;
        }
        return allCourses;
    }

    function getStudents() public view returns (address[] memory) {
        address[] memory allStudents = new address[](numberOfStudents);

        for (uint256 i = 0; i < numberOfStudents; i++) {
            address item = students[i];
            allStudents[i] = item;
        }
        return allStudents;
    }

    function getNumberOfCourses()
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory coursesForTrend = new uint256[](numberOfCourses);
        uint256[] memory numberForTrend = new uint256[](numberOfCourses);
        for (uint256 i = 0; i < numberOfCourses; i++) {
            // coursesForTrend.push(courses[i]);
            coursesForTrend[i] = courses[i].uniqueId;
            numberForTrend[i] = courses[i].consumers.length;
            // numberForTrend.push(courses[i].consumers.length);
        }
        return (coursesForTrend, numberForTrend);
    }

    function getInstructors() public view returns (Instructor[] memory) {
        Instructor[] memory allInstructors = new Instructor[](
            numberOfInstructors
        );

        for (uint256 i = 0; i < numberOfInstructors; i++) {
            Instructor storage item = instructors[i];
            allInstructors[i] = item;
        }
        return allInstructors;
    }

    function getStudentsByCourse(
        uint256 _id
    ) public view returns (address[] memory) {
        return (courses[_id].consumers);
    }

    function getStudentsByInstructor(
        uint256 _id
    ) public view returns (address[] memory) {
        return (instructors[_id].students);
    }

    function getTrendingCourses() public view returns (Course[] memory) {
        Course[] memory courseList = getCourses();

        for (uint256 i = 0; i < numberOfCourses; i++)
            for (uint256 j = 0; j < i; j++)
                if (
                    courseList[i].consumers.length >
                    courseList[j].consumers.length
                ) {
                    Course memory course = courseList[i];
                    courseList[i] = courseList[j];
                    courseList[j] = course;
                }

        return courseList;
    }
}
// function searchCourse(
//     string memory input
// ) public view returns (Course[] memory) {
//     // Create an array to store the courses that match the search criteria
//     Course[] memory matchingCourses = new Course[](0);

//     // Iterate through all courses
//     for (uint256 i = 0; i < numberOfCourses; i++) {
//         if (courses[i].title.contains(input)) {
//             // Push the course to the array of matching courses
//             matchingCourses.push(courses[i]);
//         }
//     }

//     // Return the array of matching courses
//     return matchingCourses;
// }