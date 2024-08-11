## Using TikZ drawings in Quarto is possible by using the knitr engine for TikZ:

````         
``` {r}
#| cache = TRUE
#| echo = FALSE
#| engine = 'tikz'
#| fig.ext = 'svg'
#| engine.opts = list(dvisvgm.opts = "--font-format=woff"
#| template = "./tikz-preamble.tex")
#| fig-align: center
#| label: TikZ-Test-Label
#| file: "./tikz-test.tikz"
```
````

-   placing TikZ code inside chunk instead of an external file is also possible
-   engine options can also be given in the curly braces: {r, cache = TRUE, echo = FALSE, engine = 'tikz', ...}

**But: How to get an incremental drawing working?**

## Current incremental TikZ approach

See: <https://stackoverflow.com/questions/71760913/using-tikz-in-quarto-presentation>

-   Create a drawing for each incremental step and export it to a svg image
-   place a single image on a new slide for each incrementation step
-   mark the incrementation step slides titles with `## my-title {visibility="uncounted"}`

**Drawbacks:**

-   Manual process
-   you need multiple versions of your TikZ drawing to generate the svg images
-   or you have to edit the TikZ drawing multiple times
-   Same effort neccesary when there is an update of the drawing
-   Error prone

## My approach

- Have only one complete TikZ drawing including all increments
- Insert start and end key tags into the TikZ drawing to mark the parts which have to be revealed (in my case: `% begin increment 1` and `% end increment 1`)
  ```
  % this one will be revealed on increment 1
  % begin increment number 1
    \node[draw=black, rectangle, above=of node0] (node1)
      {visible from increment 1};
    \draw[] (node0) -- (node1);
  % end increment number 1
  ```
- Use only a single slide with `{.r-stack}` and the `{.fragment}` features
- Create the incremental images on the fly by commenting out the hidded parts in the TikZ code with the help of a small bash script in a code chunk
  ```{bash}
  quarto_tikz_increments.sh -d "./" -f "./tikz-test.tikz" -i 1
  ```

  ``` 
  Syntax:
  quarto_tikz_increments [-h] [-d WORKING FOLDER] -f FILE -i INCREMENT NUMBER [-i INCREMENT NUMBER]
    -v: switch on Debug (should be first option!).
    -h: This help text!
    -d WORKING FOLDER: working directory - if not provided the current folder is used
    -f FILE: TIKZ file 
    -i INCREMENT NUMBER: one number is always required, option can be repeated multiple times;
                         if only one number is provided all increments up to that number are included.
  ```
