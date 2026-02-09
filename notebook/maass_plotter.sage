"""
This expects compiled versions of `lpkbessel.spyx` and
`maass_evaluator.spyx`. On typical machines, this can be done by typing

    make compile

in this repository. (The makefile isn't particularly portable, but there's so
little to it that it's straightforward to modify).

This also requires imagemagick (and in particular, `convert`) to be available.

# **********************************************************************
#       This is maass_plotter.sage
#       Copyright (c) 2024 David Lowry-Duda <david@lowryduda.com>
#       All Rights Reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
#                 <http://www.gnu.org/licenses/>.
# **********************************************************************
"""
from base64 import b64encode
from io import BytesIO as IO
import matplotlib as mpl
from matplotlib import cm
from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.colors import ListedColormap, LinearSegmentedColormap
import numpy as np
import subprocess
import sys
from urllib.parse import quote


from lpkbessel import besselk_dp
from maass_evaluator import maassform


DtoH = lambda x: (-CDF.0*x + 1)/(x - CDF.0)


Overall_HEX = {
    "blue": "#4677CB",
    "lilac": "#BF8FEC",
    "green": "#60B489",
    "orange": "#E69367",
    "red": "#D76055",
}
torder = ["blue", "lilac", "orange", "green", "red"]
tcmap = LinearSegmentedColormap.from_list(
    "tcmap",
    [mpl.colors.to_rgb(Overall_HEX[cname]) for cname
        in reversed(torder)]
)
tcmap_cyclic = LinearSegmentedColormap.from_list(
    "tcmap_cyclic",
    [mpl.colors.to_rgb(Overall_HEX[cname]) for cname in torder[:-1]] +
    [mpl.colors.to_rgb(Overall_HEX[cname]) for cname in reversed(torder)]
)


def make_single_plot(R, symmetry, coeffs):
    """
    Given a spectral parameter R, a symmetry (0 or 1), and a list of
    coefficients (50 are used if available), this produces a single plot.
    """
    fcc = maassform(R, symmetry, coeffs)
    P = complex_plot(
            lambda z: +Infinity if abs(z) >= 0.99 else 1j * fcc(DtoH(z)),
            (-1, 1), (-1, 1),
            plot_points=300, aspect_ratio=1, figsize=[2.2, 2.2],
            contoured=True, dark_rate=0.5, cmap="viridis")
    P.axes(False)
    return P


def make_plot_for_lmfdb_by_record(record):
    """
    For example, record could be a cursor ranging across db.maass_rigor.
    We require that record have dictionary-type access for keys
        - "maass_label"
        - "coefficients"
        - "symmetry"
        - "spectral_parameter"
    """
    label = record['maass_label']
    R = record['spectral_parameter']
    symmetry = record['symmetry']
    coeffs = record['coefficients'][:50]

    oldname = f"{label}.plot.white.png"
    newname = f"{label}.plot.png"

    P = make_single_plot(R, symmetry, coeffs)
    P.save(f"{label}.plot.white.png", figsize=[2.2, 2.2], axes=False,
            transparent=True)
    make_transparent_version(oldname, newname)
    with open(newname, "rb") as pngfile:
        data = pngfile.read()
        b64data = b64encode(data)
    return "data:image/png;base64," + quote(b64data)


def make_plot_for_lmfdb_by_label(label):
    from lmfdb import db
    record = db.maass_rigor.lucky(query={'maass_label': label})
    make_plot_for_lmfdb_by_record(record)


def make_transparent_version(oldname, newname):
    # Requires imagemagick
    subprocess.run(
        ['convert', oldname, '-fuzz', '3%', '-transparent', 'white', newname]
    )


def add_header(outfile):
    outfile.write("maass_label|portrait\n")
    outfile.write("text|text\n\n")


def make_plots_for_level(level=1):
    from lmfdb import db
    cursor = db.maass_rigor.search(query={'level': level}, projection=1)
    # it takes long enough to process all forms that the db connection might
    # grow stale. Instead, get the list and get data per form.
    all_forms = list(cursor)
    with open(f"level.{level}.plots.data", "w", encoding="utf8") as outfile:
        add_header(outfile)
        for form in all_forms:
            label = form['maass_label']
            print(label)
            record = db.maass_rigor.lookup(label)
            data = make_plot_for_lmfdb_by_record(record)
            outfile.write(f"{label}|{data}\n")


if __name__ == "__main__":
    arg = int(sys.argv[1])
    print(f"Making plots for level {arg}")
    make_plots_for_level(level=arg)
