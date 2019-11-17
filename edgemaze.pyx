# distutils: language=c++
import math

import cython
import numpy
cimport numpy
from cython.view cimport array


from libcpp cimport bool
from libcpp.set cimport set
from libcpp.pair cimport pair
from libcpp.unordered_map cimport unordered_map
from libcpp.deque cimport deque


class Solver:

    def __init__(self, directions, distances, is_reachable, arrow_directions):
        self.directions = directions
        self.distances = distances
        self.is_reachable = is_reachable
        self.arrow_directions = arrow_directions

    def path(self, int row, int column):
        path = []
        current = (row, column)

        if self.distances[current] == -1:
            raise ValueError("Nirvana is not reachable you know")

        while self.distances[current] > 0:
            path.append(current)
            arrow = self.directions[current]
            direction = self.arrow_directions[arrow]
            next = tuple(map(numpy.add, current, direction))
            current = next
        path.append(current)
        return path

@cython.boundscheck(False)
@cython.wraparound(False)
cdef bool coord_valid(int y, int x, numpy.uint8_t[:, :] maze):
    return 0 <= y < maze.shape[0] and 0 <= x < maze.shape[1]

@cython.boundscheck(False)
@cython.wraparound(False)
cdef bool can_go_there(pair[numpy.int64_t, numpy.int64_t] expanding, pair[numpy.int64_t, numpy.int64_t] adjacent, numpy.uint8_t[:, :] maze):
    if coord_valid(adjacent.first, adjacent.second, maze):
            if expanding.first < adjacent.first:
                return maze[adjacent.first][adjacent.second] & 4 == 0
            elif adjacent.first < expanding.first:
                return maze[expanding.first][expanding.second] & 4 == 0
            if expanding.second < adjacent.second:
                return maze[adjacent.first][adjacent.second] & 2 == 0
            elif adjacent.second < expanding.second:
                return maze[expanding.first][expanding.second] & 2 == 0
    else:
        return False

@cython.boundscheck(False)
@cython.wraparound(False)
cdef solve(numpy.ndarray[numpy.uint8_t, ndim=2] maze):
    cdef unordered_map[numpy.uint8_t, pair[numpy.int64_t, numpy.int64_t]] arrow_directions
    arrow_directions.insert((ord('>'), (0, -1)))
    arrow_directions.insert((ord('v'), (-1, 0)))
    arrow_directions.insert((ord('<'), (0, 1)))
    arrow_directions.insert((ord('^'), (1, 0)))

    cdef unordered_map[char*, pair[numpy.int64_t, numpy.int64_t]] reverse_arrow_directions
    reverse_arrow_directions.insert((b'>', (0, 1)))
    reverse_arrow_directions.insert((b'v', (1, 0)))
    reverse_arrow_directions.insert((b'<', (0, -1)))
    reverse_arrow_directions.insert((b'^', (-1, 0)))

    cdef numpy.uint8_t[:, :] mem_maze = maze

    cdef numpy.ndarray[numpy.int64_t, ndim=2] distances = numpy.ndarray((maze.shape[0], maze.shape[1]), numpy.int64)
    #distances = numpy.zeros_like(maze, int)
    #distances[maze & 1 == 1] = 0

    cdef numpy.int64_t[:, :] mem_distances = distances

    cdef numpy.ndarray[numpy.uint8_t, ndim=2] directions = numpy.ndarray((maze.shape[0], maze.shape[1]), numpy.uint8)

    #directions = numpy.full_like(maze, ord(' '))
    #directions[maze & 1 == 1] = ord('X')
    cdef numpy.uint8_t[:, :] mem_directions = directions

    cdef deque[pair[numpy.int64_t, numpy.int64_t]] to_test

    for i in range(maze.shape[0]):
        for j in range(maze.shape[1]):
            if mem_maze[i][j] & 1 == 1:
                mem_distances[i][j] = 0
                mem_directions[i][j] = <numpy.uint8_t>88
                to_test.push_back(pair[numpy.int64_t, numpy.int64_t](i, j))
            else:
                mem_distances[i][j] = -1
                mem_directions[i][j] = <numpy.uint8_t>32


    cdef pair[numpy.int64_t, numpy.int64_t] adjacent, expanding, direction
    cdef numpy.int64_t x, y
    cdef numpy.uint8_t arrow
    cdef numpy.int64_t distance
    while not to_test.empty():
        expanding = to_test.front()
        to_test.pop_front()

        distance = mem_distances[expanding.first][expanding.second]
        for arrowpair in arrow_directions:
            arrow = arrowpair.first
            direction = arrowpair.second
            y = expanding.first + direction.first
            x = expanding.second + direction.second
            adjacent = pair[numpy.int64_t, numpy.int64_t](y, x)

            if (can_go_there(expanding, adjacent, mem_maze) and
                mem_distances[y][x] == -1 and
                    mem_distances[adjacent.first][adjacent.second] == -1):
                to_test.push_back(adjacent)
                mem_directions[adjacent.first][adjacent.second] = arrow
                mem_distances[adjacent.first][adjacent.second] = distance+1

    cdef bool is_reachable = True

    for i in range(maze.shape[0]):
        for j in range(maze.shape[1]):
            if mem_distances[i][j] == -1:
                is_reachable = False

    return directions, distances, is_reachable, reverse_arrow_directions

def analyze(maze):
    if maze.ndim != 2:
        raise TypeError("dimension mansion")
    if not numpy.issubdtype(maze.dtype, numpy.integer):
        raise TypeError("input must be integers")
    maze = maze.astype(numpy.uint8)
    cdef numpy.ndarray[numpy.uint8_t, ndim=2] directions
    cdef numpy.ndarray[numpy.int64_t, ndim=2] distances
    directions, distances, is_reachable, arrow_directions = solve(maze)
    solver = Solver(directions.view('c').astype(('a', 1)), distances, is_reachable, arrow_directions)
    return solver
