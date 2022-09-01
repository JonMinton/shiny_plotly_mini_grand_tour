# shiny_plotly_mini_grand_tour
Repo for developing best practice for interrogating time-varying spatial data such that choropleth clicks and slider movements both lead to updated time-varying and place-varying mini views

# Background 

Imagine you have two datasets

- `dta_sf`: Spatial data (in `sf` format, though this might not be essential)
- `dta_vars`: Population data

Both datasets have a spatial key column `place`

`dta_vars` has the following columns:

- `place`: the spatial key
- `year`: the year for which the observation holds
- `var`: one or more variables
- `sex`: `male`, `female`, and possibly `total`
- `value.point`: The point estimate for the variable `var`, in place `place`, in year `year`, in sex `sex`.
- `value.lower`: Lower CI for `value.point`
- `value.upper`: Upper CI for `value.point`

# Overall aim 

Produce a Shiny + Plotly app comprising the following high-level Shiny inputs:

- `var_select`: which variable to visualise
- `sex_select`: which sex to focus on (optional: can do both by default)

This above selection will then cause the following to be generated: 

- `plot_map`: One (single sex) or two (both sexes) choropleths for variable `var`. This will include the following features:
    - **year slider**: A slider which allows the user to select a year, defaulting to the first available year. The choropleth fill colours will automatically update to the year selected by the slider
    - **hover over tooltips**: When the user hovers over a geography in the choropleth, the tooltip will report the year `year`, variable `var`, (sex: optional), `value.point`, `value.lower`, and `value.upper` as an appropriately formatted string
    
When the user **clicks** on a geography in the choropleth, a secondary plot `plot_tour` comprising two subplots will then be generated or updated accordingly: 

- `plot_tour` comprises:
    - `plot_time_varying`: For geography `place`, how does `value.point` vary over time? 
        - Time `year` (from slider) highlighted as a point on this subplot.
        - Option to also display `value.lower` and `value.upper` as ribbon on same subplot
    - `plot_place_varying`: For the time `year` (from slider), how does place `place` compare with other places?
        - Places automatically ordered from lowest to highest (or vice versa) `value.point`
            - option to change order (lowest/highest/alphabetical?)
        - Place `place` is highlighted with different colour/shape type.
        - Option to show `value.lower` and `value.upper` alongside `value.point` (i.e. horizontal lines alongside dotchart)
        

# Challenges 

- How to identify `place` selected by user click action?
    - `plotly::event_register` and `plotly::event_data` allow events to be recorded within a shiny session, and shared between elements
    - Challenge 1: The default way of graphing `sf` maps in plotly involves specifying `split = ~place`, producing one trace per geography
        - the resulting `event_data` on click then returns a single attribute `curveNumber` rather than additional details about the geography selected
        - therefore need to robustly match `curveNumber` to applicable rows in `dta_vars` 
    - Challenge 2: The default way of generating a year slider is to set the argument `frame = ~year` in `plot_ly`.
        - This creates an element of type `crosstalk::filter_select` which is integrated within the plotly object `p` returned by `plot_map`
        - Whereas `plotly::event_register` and `plotly::event_data` provide a means by which click events on the plotly canvas can be shared between shiny elements, there appears to be no direct equivalent way of registering and sharing slide events (moving the year slider) between shiny elements
        - Accessing/sharing these slide events may either require
            - Using lower level code to generate the `crosstalk::filter_select` element; and/or
            - Using javascript calls to listen to and share changes in the value of the `crosstalk::filter_select` element contained in this part of `plot_map` such that it can be accessed by logic in `plot_tour` 
