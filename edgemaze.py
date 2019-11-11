import math

import numpy

arrow_directions = {b'>': (0, -1), b'v': (-1, 0), b'<': (0, 1), b'^': (1, 0)}

class Solver:

    def __init__(self, maze):
        self.maze = maze
        self.distances = numpy.full_like(maze, -1, int)
        self.distances[maze & 1 == 1] = 0
        self.directions = numpy.full_like(maze, b' ', ('a', 1))
        self.directions[maze & 1 == 1] = "X"
        self.starting_points = maze & 1
        self.is_reachable = False

    def solve(self):
        start_points = numpy.where(self.starting_points == 1)
        if start_points:
            to_test = list(zip(start_points[0], start_points[1]))
            to_test_set = set(zip(start_points[0], start_points[1]))

        while to_test:
            expanding = to_test.pop(0)
            to_test_set.remove(expanding)

            distance = self.distances[expanding]

            for arrow, direction in arrow_directions.items():
                adjacent = tuple(map(numpy.add, expanding, direction))

                if (self.can_go_there(expanding, adjacent) and
                    adjacent not in to_test_set
                        and self.distances[adjacent] == -1):

                    to_test.append(adjacent)
                    to_test_set.add(adjacent)
                    self.directions[adjacent] = arrow
                    self.distances[adjacent] = distance+1

        self.is_reachable = not numpy.any(self.distances == -1)

    def path(self, row, collumn):
        path = []
        current = (row, collumn)

        if self.distances[current] == -1:
            raise ValueError("Nirvana is not reachable you know")

        while self.distances[current] > 0:
            path.append(current)
            arrow = self.directions[current]
            direction = tuple(map(lambda num: -1*num, arrow_directions[arrow]))
            next = tuple(map(numpy.add, current, direction))
            current = next
        path.append(current)
        return path

    def can_go_there(self, expanding, adjacent):
        if self.coord_valid(*adjacent):
            if expanding[0] < adjacent[0]:
                return self.maze[adjacent] & 4 == 0
            elif expanding[0] > adjacent[0]:
                return self.maze[expanding] & 4 == 0
            elif expanding[1] < adjacent[1]:
                return self.maze[adjacent] & 2 == 0
            elif expanding[1] > adjacent[1]:
                return self.maze[expanding] & 2 == 0
        else:
            return False

    def coord_valid(self, x, y):
        return 0 <= x < self.maze.shape[0] and 0 <= y < self.maze.shape[1]


def analyze(maze):
    if maze.ndim != 2:
        raise TypeError("dimension mansion")
    solver = Solver(maze)
    solver.solve()
    return solver